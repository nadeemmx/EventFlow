"""Pre-production operations tests: health/readiness/liveness endpoints and
security response headers.

Covers checklist items for monitoring/observability (#33) and part of
security headers verification (#18/#20). The degraded-readiness path is
exercised by breaking the DB connection so the 503 contract is proven rather
than assumed.
"""
import json
from unittest import mock

from django.db.utils import OperationalError
from rest_framework.test import APITestCase


class HealthEndpointTests(APITestCase):
    def test_liveness_returns_200(self):
        response = self.client.get("/live/")
        self.assertEqual(response.status_code, 200)
        body = json.loads(response.content)
        self.assertEqual(body["status"], "alive")

    def test_health_returns_200_with_version_and_timestamp(self):
        response = self.client.get("/health/")
        self.assertEqual(response.status_code, 200)
        body = json.loads(response.content)
        self.assertEqual(body["status"], "ok")
        self.assertIn("version", body)
        self.assertIn("timestamp", body)

    def test_readiness_all_checks_green_returns_200(self):
        response = self.client.get("/ready/")
        self.assertEqual(response.status_code, 200, response.content)
        body = json.loads(response.content)
        self.assertEqual(body["status"], "ok")
        for check in ("database", "migrations", "redis"):
            self.assertTrue(body["checks"][check], f"{check} check not green")

    def test_readiness_degrades_to_503_when_database_unreachable(self):
        """core/health.py:54-59 - any failing check must flip the probe to
        503 so a load balancer pulls the instance out of rotation."""
        with mock.patch(
            "django.db.connection.ensure_connection",
            side_effect=OperationalError("db down"),
        ):
            response = self.client.get("/ready/")
        self.assertEqual(response.status_code, 503, response.content)
        body = json.loads(response.content)
        self.assertEqual(body["status"], "degraded")
        self.assertFalse(body["checks"]["database"])

    def test_readiness_ignores_cache_failure_shape(self):
        """Readiness must never 500 while assembling the report."""
        with mock.patch(
            "django.core.cache.cache.set",
            side_effect=Exception("cache down"),
        ):
            response = self.client.get("/ready/")
        self.assertIn(response.status_code, (200, 503))
        body = json.loads(response.content)
        self.assertFalse(body["checks"]["redis"])


class SecurityHeaderTests(APITestCase):
    def test_api_responses_carry_security_and_observability_headers(self):
        response = self.client.get("/health/")
        for header in (
            "X-Frame-Options",
            "X-Content-Type-Options",
            "Referrer-Policy",
            "X-Request-ID",
        ):
            self.assertIn(header, response.headers, f"missing {header}")
        self.assertEqual(response.headers["X-Frame-Options"], "DENY")
        self.assertEqual(response.headers["X-Content-Type-Options"], "nosniff")

    def test_error_responses_do_not_leak_server_stack(self):
        response = self.client.get("/api/v1/customers/", HTTP_ACCEPT="application/json")
        self.assertIn(response.status_code, (200, 401))
        content = response.content.decode()
        self.assertNotIn("Traceback", content)
        self.assertNotIn("site-packages", content)

    def test_cors_reflects_only_allowed_origin(self):
        allowed = self.client.options(
            "/api/v1/customers/",
            HTTP_ORIGIN="http://localhost:3000",
            HTTP_ACCESS_CONTROL_REQUEST_METHOD="GET",
        )
        self.assertEqual(allowed.status_code, 200)
        self.assertEqual(
            allowed.headers.get("Access-Control-Allow-Origin"),
            "http://localhost:3000",
        )

        disallowed = self.client.options(
            "/api/v1/customers/",
            HTTP_ORIGIN="https://evil.example",
            HTTP_ACCESS_CONTROL_REQUEST_METHOD="GET",
        )
        self.assertFalse(
            disallowed.headers.get("Access-Control-Allow-Origin"),
            "CORS must not reflect an untrusted origin",
        )
