"""Pre-production authentication, JWT and transport security tests.

Covers checklist items #16 (Rate Limiting & Throttling), #17 (Security /
OWASP), #18 (Penetration - session & token tampering) and
#20 (Authentication & Authorization).
"""
import json
from contextlib import contextmanager
from datetime import timedelta
from unittest import mock

from django.core.cache import cache
from django.test import Client, signals as test_signals
from rest_framework.settings import api_settings
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import AccessToken

from apps.tenants.models import Tenant
from apps.users.models import User
from core.choices import UserRole


PROTECTED_ENDPOINTS = [
    "bookings", "customers", "venues", "payments", "invoices", "leads",
    "users", "dashboard/summary",
]


class TokenSecurityTestBase(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Security Venue", owner_name="Owner",
            email="security@test.com", mobile="9000000101",
        )
        self.owner = User.objects.create_user(
            email="security-owner@test.com", password="SecurityPass123!",
            full_name="Owner", tenant=self.tenant, role=UserRole.OWNER,
        )

    def _bearer(self, token):
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")


class AuthenticationRequiredTests(TokenSecurityTestBase):
    def test_all_protected_endpoints_reject_anonymous(self):
        for endpoint in PROTECTED_ENDPOINTS:
            with self.subTest(endpoint=endpoint):
                response = self.client.get(f"/api/v1/{endpoint}/")
                self.assertEqual(response.status_code, 401, endpoint)
                body = json.loads(response.content)
                self.assertFalse(body["success"])

    def test_garbage_token_rejected(self):
        for token in ["not-a-jwt", "Bearer nonsense", "a" * 500,
                      "eyJhbGciOiJub25lIn0.eyJ1c2VyX2lkIjoxfQ."]:
            with self.subTest(token=token[:20]):
                self._bearer(token)
                response = self.client.get("/api/v1/bookings/")
                self.assertEqual(response.status_code, 401)

    def test_expired_token_rejected(self):
        token = AccessToken.for_user(self.owner)
        token.set_exp(lifetime=timedelta(seconds=-30))
        self._bearer(str(token))
        response = self.client.get("/api/v1/bookings/")
        self.assertEqual(response.status_code, 401, response.content)

    def test_tampered_signature_rejected(self):
        token = str(AccessToken.for_user(self.owner))
        head, payload, sig = token.split(".")
        tampered_sig = ("A" if sig[0] != "A" else "B") + sig[1:]
        self._bearer(f"{head}.{payload}.{tampered_sig}")
        self.assertEqual(self.client.get("/api/v1/bookings/").status_code, 401)

    def test_tampered_payload_rejected(self):
        import base64
        token = str(AccessToken.for_user(self.owner))
        head, payload, sig = token.split(".")
        padding = "=" * (-len(payload) % 4)
        data = json.loads(base64.urlsafe_b64decode(payload + padding))
        data["user_id"] = 999999
        data["is_superuser"] = True
        new_payload = base64.urlsafe_b64encode(
            json.dumps(data).encode()
        ).decode().rstrip("=")
        self._bearer(f"{head}.{new_payload}.{sig}")
        self.assertEqual(self.client.get("/api/v1/bookings/").status_code, 401)

    def test_token_with_wrong_algorithm_rejected(self):
        token = str(AccessToken.for_user(self.owner))
        head, payload, sig = token.split(".")
        none_head = base64url({"alg": "none", "typ": "JWT"})
        self._bearer(f"{none_head}.{payload}.")
        self.assertEqual(self.client.get("/api/v1/bookings/").status_code, 401)

    def test_inactive_user_token_rejected(self):
        token = str(AccessToken.for_user(self.owner))
        self.owner.is_active = False
        self.owner.save(update_fields=["is_active"])
        self._bearer(token)
        self.assertIn(self.client.get("/api/v1/bookings/").status_code, (401, 403))

    def test_login_response_never_contains_password_material(self):
        response = self.client.post(
            "/api/v1/auth/login/",
            {"email": "security-owner@test.com", "password": "SecurityPass123!"},
        )
        self.assertEqual(response.status_code, 200)
        raw = response.content.decode().lower()
        for forbidden in ("password", "SecurityPass123!".lower(), "pbkdf2", "set_password"):
            self.assertNotIn(forbidden, raw)

    def test_stored_password_is_hashed(self):
        self.assertTrue(self.owner.password.startswith(("pbkdf2", "argon2", "md5$")))
        self.assertNotEqual(self.owner.password, "SecurityPass123!")

    def test_profile_endpoint_does_not_leak_other_users(self):
        token = str(AccessToken.for_user(self.owner))
        self._bearer(token)
        body = json.loads(self.client.get("/api/v1/profile/").content)["data"]
        self.assertNotIn("password", body)
        self.assertEqual(body["id"], self.owner.id)


def base64url(obj):
    import base64, json as _json
    return base64.urlsafe_b64encode(_json.dumps(obj).encode()).decode().rstrip("=")


class LogoutSessionTests(TokenSecurityTestBase):
    def setUp(self):
        super().setUp()
        login = self.client.post(
            "/api/v1/auth/login/",
            {"email": "security-owner@test.com", "password": "SecurityPass123!"},
        )
        self.assertEqual(login.status_code, 200)
        self.tokens = json.loads(login.content)["data"]

    def test_logout_revokes_refresh_token(self):
        access = self.tokens["access_token"]
        refresh = self.tokens["refresh_token"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
        response = self.client.post("/api/v1/auth/logout/", {"refresh_token": refresh})
        self.assertEqual(response.status_code, 200, response.content)

        reuse = self.client.post("/api/v1/auth/logout/", {"refresh_token": refresh})
        self.assertIn(reuse.status_code, (200, 400, 401))

        self.client.credentials()
        refreshed = self.client.post(
            "/api/v1/auth/refresh/", {"refresh_token": refresh}
        )
        self.assertEqual(
            refreshed.status_code, 401,
            f"blacklisted refresh token must be rejected: {refreshed.content}",
        )

    def test_access_token_lifetime_is_bounded(self):
        from django.conf import settings as s
        lifetime = s.SIMPLE_JWT["ACCESS_TOKEN_LIFETIME"]
        self.assertLessEqual(lifetime.total_seconds(), 2 * 60 * 60,
                             "access token lives longer than 2h")


class RateLimitingTests(TokenSecurityTestBase):
    """Throttling is deliberately relaxed in local/test settings (10000/min);
    these tests tighten the live DRF api_settings to prove the enforcement
    path really rejects floods with 429."""

    @contextmanager
    def _strict_rates(self, rates):
        original = dict(api_settings.DEFAULT_THROTTLE_RATES)
        api_settings.DEFAULT_THROTTLE_RATES.update(rates)
        cache.clear()
        try:
            yield
        finally:
            api_settings.DEFAULT_THROTTLE_RATES.clear()
            api_settings.DEFAULT_THROTTLE_RATES.update(original)
            cache.clear()

    def test_login_throttle_returns_429(self):
        payload = {"email": "security-owner@test.com", "password": "WrongPassword1!"}
        statuses = []
        with self._strict_rates({"login": "3/minute"}):
            for _ in range(5):
                statuses.append(
                    self.client.post("/api/v1/auth/login/", payload).status_code
                )
        self.assertIn(429, statuses, f"no throttling observed: {statuses}")
        self.assertEqual(statuses[0], 401, "first attempt must reach the view")

    def test_forgot_password_throttle_returns_429(self):
        statuses = []
        with self._strict_rates({"forgot_password": "2/minute"}):
            for _ in range(4):
                statuses.append(self.client.post(
                    "/api/v1/auth/forgot-password/",
                    {"email": "security-owner@test.com"},
                ).status_code)
        self.assertIn(429, statuses, f"no throttling observed: {statuses}")

    def test_throttled_response_uses_json_envelope(self):
        response = None
        with self._strict_rates({"login": "1/minute"}):
            for _ in range(3):
                response = self.client.post(
                    "/api/v1/auth/login/",
                    {"email": "security-owner@test.com", "password": "nope"},
                )
        self.assertEqual(response.status_code, 429, response.content)
        body = json.loads(response.content)
        self.assertIn("success", body)
        self.assertFalse(body["success"])
        self.assertIn("message", body)

    def test_throttle_is_per_client_not_global(self):
        """A flood from one IP must not lock out a different client."""
        with self._strict_rates({"login": "1/minute"}):
            self.client.post("/api/v1/auth/login/",
                             {"email": "security-owner@test.com", "password": "nope"})
            flooded = self.client.post("/api/v1/auth/login/",
                                       {"email": "security-owner@test.com",
                                        "password": "nope"})
            self.assertEqual(flooded.status_code, 429)
            other = Client()
            other_response = other.post(
                "/api/v1/auth/login/",
                {"email": "security-owner@test.com", "password": "nope"},
                REMOTE_ADDR="10.1.2.3",
            )
        self.assertEqual(other_response.status_code, 401)


class CsrfAndHeaderTests(TokenSecurityTestBase):
    def test_admin_post_without_csrf_token_rejected(self):
        client = Client(enforce_csrf_checks=True)
        with mock.patch.object(test_signals.template_rendered, "send",
                               lambda *a, **k: None):
            response = client.post(
                "/admin/login/", {"username": "x", "password": "y"}
            )
        self.assertEqual(response.status_code, 403)
        self.assertIn("CSRF", response.content.decode())

    def test_security_headers_present(self):
        response = self.client.get("/health/")
        self.assertEqual(response.headers.get("X-Frame-Options"), "DENY")
        self.assertEqual(response.headers.get("X-Content-Type-Options"), "nosniff")
        self.assertIn(response.headers.get("Referrer-Policy"), ("same-origin", "strict-origin-when-cross-origin"))

    def test_production_settings_fail_closed_without_secrets(self):
        """Production settings must refuse to boot when secrets are missing
        instead of falling back to development defaults."""
        import importlib
        import os
        import sys
        from unittest import mock

        sys.modules.pop("config.settings.production", None)
        env = {"DJANGO_SECRET_KEY": "", "REDIS_URL": "", "ENCRYPTION_KEY": ""}
        with mock.patch.dict(os.environ, env, clear=False):
            for key in env:
                os.environ.pop(key, None)
            with self.assertRaises(ValueError):
                importlib.import_module("config.settings.production")
        sys.modules.pop("config.settings.production", None)

    def test_production_settings_declare_hardening(self):
        """Static guard: the hardening directives must stay in production.py.

        The module itself cannot be imported here - it deliberately raises
        without DJANGO_SECRET_KEY/REDIS_URL/ENCRYPTION_KEY (see the test
        above), so the file is inspected as source instead."""
        from pathlib import Path
        import config.settings

        source = (Path(config.settings.__file__).parent / "production.py").read_text()
        for directive in (
            "DEBUG = False",
            "SECURE_HSTS_SECONDS = 31536000",
            "SECURE_CONTENT_TYPE_NOSNIFF = True",
            "X_FRAME_OPTIONS = \"DENY\"",
            "SESSION_COOKIE_SECURE = True",
            "CSRF_COOKIE_SECURE = True",
            "SESSION_COOKIE_HTTPONLY = True",
        ):
            self.assertIn(directive, source, f"missing hardening: {directive}")
