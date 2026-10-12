"""Regression tests for QA-TEST-REPORT-ROLES.md F-3 (P2).

Logout blacklisted only the *refresh* token, so the access token presented on
the logout request kept authenticating for the rest of its 60-minute lifetime.
A stolen access token therefore survived the user "logging out" — the exact
thing a user believes logout does.

The fix blacklists the presented access token as well. Sibling tokens from
other devices are intentionally left alone: logging out of one session must
not kill every other session.
"""
from django.test import TransactionTestCase
from rest_framework.test import APIClient

from apps.tenants.models import Tenant
from apps.users.models import User
from core.choices import UserRole


def _login(client, email, password):
    resp = client.post(
        "/api/v1/auth/login/",
        {"email": email, "password": password}, format="json")
    assert resp.status_code == 200, resp.data
    return resp.data["data"]


def _auth(client, access_token):
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {access_token}")


class LogoutRevokesAccessTokenTests(TransactionTestCase):
    """``TransactionTestCase``: blacklisting writes rows that a rolled-back
    ``TestCase`` atomic block would discard, hiding the behaviour under test."""

    def setUp(self):
        self.client = APIClient()
        self.tenant = Tenant.objects.create(
            business_name="Alpha Events", owner_name="Owner",
            email="alpha@test.com", mobile="9999999999", status="ACTIVE")
        self.owner = User.objects.create_user(
            email="owner@test.com", password="ownerpass123",
            full_name="Tenant Owner", tenant=self.tenant, role=UserRole.OWNER)

    def test_access_token_stops_authenticating_after_logout(self):
        tokens = _login(self.client, "owner@test.com", "ownerpass123")
        access = tokens["access_token"]

        # token works before logout
        _auth(self.client, access)
        self.assertEqual(self.client.get("/api/v1/customers/").status_code, 200)

        # log out using that same access token
        resp = self.client.post(
            "/api/v1/auth/logout/",
            {"refresh_token": tokens["refresh_token"]}, format="json")
        self.assertEqual(resp.status_code, 200, resp.data)

        # ...and it must be dead immediately
        _auth(self.client, access)
        after = self.client.get("/api/v1/customers/")
        self.assertEqual(
            after.status_code, 401,
            f"access token still valid after logout: {after.status_code}")

    def test_refresh_token_is_still_blacklisted(self):
        """No regression on the existing refresh blacklisting."""
        tokens = _login(self.client, "owner@test.com", "ownerpass123")
        _auth(self.client, tokens["access_token"])
        self.assertEqual(
            self.client.post("/api/v1/auth/logout/",
                             {"refresh_token": tokens["refresh_token"]},
                             format="json").status_code, 200)
        replay = self.client.post(
            "/api/v1/auth/refresh/",
            {"refresh_token": tokens["refresh_token"]}, format="json")
        self.assertEqual(replay.status_code, 401, replay.data)

    def test_logout_of_one_session_leaves_a_sibling_session_alive(self):
        """Logging out of one device must not kill another."""
        tokens_a = _login(self.client, "owner@test.com", "ownerpass123")
        tokens_b = _login(self.client, "owner@test.com", "ownerpass123")

        _auth(self.client, tokens_a["access_token"])
        self.assertEqual(
            self.client.post("/api/v1/auth/logout/",
                             {"refresh_token": tokens_a["refresh_token"]},
                             format="json").status_code, 200)

        _auth(self.client, tokens_b["access_token"])
        self.assertEqual(
            self.client.get("/api/v1/customers/").status_code, 200,
            "logging out one session must not revoke a sibling session")
