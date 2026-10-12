"""Pre-production API contract tests.

Covers checklist items #3 (Functional), #9 (API Testing) and #6 (Smoke):
every API surface must answer with JSON, a stable envelope, and a sane
status code so API clients (Next.js frontend, mobile app) never receive an
HTML page they cannot parse.
"""
import json
from unittest import mock

from django.test import override_settings, signals as test_signals
from rest_framework.test import APITestCase

from apps.tenants.models import Tenant
from apps.users.models import User


PAGINATED_ENDPOINTS = [
    "customers", "leads", "venues", "bookings", "payments", "invoices",
    "vendors", "inventory", "staff", "tasks", "expenses", "notifications",
    "users", "packages", "audit-logs", "privacy/requests",
]

ENVELOPE_ENDPOINTS = [
    "dashboard/summary", "profile", "contracts", "quotations", "subscriptions",
]


class ApiContractTests(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Contract Venue", owner_name="Owner",
            email="contract@test.com", mobile="9000000001",
        )
        self.owner = User.objects.create_user(
            email="contract-owner@test.com", password="ContractPass123!",
            full_name="Owner", tenant=self.tenant, role="OWNER",
        )
        self.client.force_authenticate(user=self.owner)

    def test_health_endpoint_is_ok(self):
        response = self.client.get("/health/")
        self.assertEqual(response.status_code, 200)
        body = json.loads(response.content)
        self.assertEqual(body["status"], "ok")
        self.assertIn("version", body)

    def test_readiness_reports_database_and_migrations(self):
        response = self.client.get("/ready/")
        self.assertIn(response.status_code, (200, 503))
        body = json.loads(response.content)
        self.assertTrue(body["checks"]["database"], "DB check must pass")
        self.assertTrue(body["checks"]["migrations"], "no pending migrations allowed")
        if response.status_code == 200:
            self.assertEqual(body["status"], "ok")

    def test_liveness_endpoint(self):
        response = self.client.get("/live/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.content)["status"], "alive")

    def test_paginated_list_endpoints(self):
        for endpoint in PAGINATED_ENDPOINTS:
            with self.subTest(endpoint=endpoint):
                response = self.client.get(f"/api/v1/{endpoint}/")
                self.assertEqual(response.status_code, 200, endpoint)
                self.assertTrue(response["Content-Type"].startswith("application/json"), endpoint)
                body = json.loads(response.content)
                self.assertIn("results", body, endpoint)
                self.assertIn("count", body, endpoint)
                self.assertIsInstance(body["results"], list, endpoint)

    def test_envelope_list_endpoints(self):
        for endpoint in ENVELOPE_ENDPOINTS:
            with self.subTest(endpoint=endpoint):
                response = self.client.get(f"/api/v1/{endpoint}/")
                self.assertEqual(response.status_code, 200, endpoint)
                body = json.loads(response.content)
                self.assertTrue(body.get("success"), endpoint)
                self.assertIn("data", body, endpoint)

    def test_unknown_resource_returns_json_404(self):
        response = self.client.get("/api/v1/customers/999999/")
        self.assertEqual(response.status_code, 404)
        self.assertTrue(response["Content-Type"].startswith("application/json"))
        body = json.loads(response.content)
        self.assertFalse(body["success"])
        self.assertIn("message", body)

    def test_invalid_pagination_returns_json_error(self):
        response = self.client.get("/api/v1/customers/?page=not-a-number")
        self.assertEqual(response.status_code, 404)
        body = json.loads(response.content)
        self.assertFalse(body["success"])

    def test_unauthenticated_request_is_json_401(self):
        self.client.force_authenticate(user=None)
        response = self.client.get("/api/v1/bookings/")
        self.assertEqual(response.status_code, 401)
        self.assertTrue(response["Content-Type"].startswith("application/json"))
        body = json.loads(response.content)
        self.assertFalse(body["success"])
        self.assertNotIn("detail", body, "raw DRF detail leaks through the envelope")

    def test_method_not_allowed_is_json_405(self):
        response = self.client.delete("/api/v1/auth/login/")
        self.assertEqual(response.status_code, 405)
        self.assertTrue(response["Content-Type"].startswith("application/json"))
        body = json.loads(response.content)
        self.assertFalse(body["success"])
        self.assertIn("message", body)

    @override_settings(CORS_ALLOWED_ORIGINS=["http://localhost:3000"])
    def test_cors_preflight_allows_local_frontend(self):
        response = self.client.options(
            "/api/v1/auth/login/",
            HTTP_ORIGIN="http://localhost:3000",
            HTTP_ACCESS_CONTROL_REQUEST_METHOD="POST",
            HTTP_ACCESS_CONTROL_REQUEST_HEADERS="authorization,content-type",
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Access-Control-Allow-Origin"], "http://localhost:3000")
        self.assertEqual(response["Access-Control-Allow-Credentials"], "true")

    def test_dashboard_summary_has_business_metrics(self):
        response = self.client.get("/api/v1/dashboard/summary/")
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.content)["data"]
        for key in ("today_events", "upcoming_bookings", "pending_payments",
                    "active_leads", "monthly_revenue"):
            self.assertIn(key, data)

    def test_report_actions_are_reachable(self):
        for action in ("revenue", "bookings", "payments", "occupancy", "leads"):
            with self.subTest(action=action):
                response = self.client.get(f"/api/v1/reports/{action}/")
                self.assertEqual(response.status_code, 200, action)
                body = json.loads(response.content)
                self.assertTrue(body.get("success"), action)

    def test_settings_actions_are_reachable(self):
        for action in ("organization", "invoice", "booking", "notifications", "security"):
            with self.subTest(action=action):
                response = self.client.get(f"/api/v1/settings/{action}/")
                self.assertEqual(response.status_code, 200, action)

    def test_error_envelope_is_stable(self):
        """Every error body uses {success, message, errors} - clients rely on it."""
        self.client.force_authenticate(user=None)
        responses = [
            self.client.get("/api/v1/bookings/"),          # 401
            self.client.get("/api/v1/customers/999999/"),  # 404
        ]
        for response in responses:
            body = json.loads(response.content)
            self.assertEqual(
                sorted(body.keys()), ["errors", "message", "success"],
                f"unexpected error envelope for {response.status_code}: {body}",
            )

    # --- known gaps documented as findings (see QA report) -----------------

    def _get_no_render_capture(self, path):
        """Django 4.2 + Python 3.14: the test client's template_rendered
        receiver crashes on Context.__copy__. Silence render instrumentation
        so the real HTML error page can be inspected."""
        with mock.patch.object(test_signals.template_rendered, "send",
                               lambda *a, **k: None):
            return self.client.get(path)

    def test_unknown_api_route_is_json_404(self):
        """Closed by the /api/v1/<path> catch-all in config/urls.py
        (QA-TEST-REPORT-ROLES.md F-6 / P2-API-01). Was a known gap."""
        response = self._get_no_render_capture("/api/v1/definitely-not-a-route/")
        self.assertEqual(response.status_code, 404)
        self.assertTrue(
            response["Content-Type"].startswith("application/json"),
            f"API 404 must be JSON, got {response['Content-Type']}",
        )

    def test_reports_collection_get_is_json_404(self):
        """/api/v1/reports/ has no list route (GenericViewSet + @action only),
        so it now falls through to the JSON catch-all (P2-API-02)."""
        response = self._get_no_render_capture("/api/v1/reports/")
        self.assertEqual(response.status_code, 404)
        self.assertTrue(
            response["Content-Type"].startswith("application/json"),
            f"reports collection GET must be JSON, got {response['Content-Type']}",
        )

    def test_settings_collection_get_is_json_404(self):
        """/api/v1/settings/ has no list route, so it now falls through to the
        JSON catch-all (P2-API-02)."""
        response = self._get_no_render_capture("/api/v1/settings/")
        self.assertEqual(response.status_code, 404)
        self.assertTrue(
            response["Content-Type"].startswith("application/json"),
            f"settings collection GET must be JSON, got {response['Content-Type']}",
        )
