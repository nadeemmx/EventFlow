"""Regression tests for QA-TEST-REPORT-ROLES.md F-6 (P3).

Unmatched ``/api/v1/...`` paths fell through to Django's default 404 handler,
which renders HTML. An API client parsing JSON failed on the content type
before it ever saw the 404 status.

``config/urls.py`` registers a catch-all after the router that answers JSON
for API paths only; the rest of the site keeps Django's HTML 404.
"""
import json

from django.test import TestCase, override_settings


class ApiNotFoundTests(TestCase):
    def test_unknown_api_route_returns_json_404(self):
        resp = self.client.get("/api/v1/this-route-does-not-exist/")
        self.assertEqual(resp.status_code, 404)
        self.assertIn("application/json", resp["Content-Type"])
        body = json.loads(resp.content)
        self.assertEqual(body["success"], False)
        self.assertIn("message", body)
        self.assertIn("errors", body)

    def test_unknown_nested_api_route_returns_json_404(self):
        resp = self.client.get("/api/v1/customers/1/not-an-action/")
        self.assertEqual(resp.status_code, 404)
        self.assertIn("application/json", resp["Content-Type"])
        self.assertEqual(json.loads(resp.content)["success"], False)

    def test_every_method_gets_json_not_html(self):
        for method in ("get", "post", "put", "patch", "delete"):
            with self.subTest(method=method):
                resp = getattr(self.client, method)(
                    "/api/v1/nope/")
                self.assertEqual(resp.status_code, 404)
                self.assertIn("application/json", resp["Content-Type"])

    def test_real_api_routes_are_not_shadowed(self):
        """The catch-all must sit behind the router, not in front of it.

        ``/api/v1/customers/`` requires auth, so 401 proves DRF answered and
        the catch-all did not swallow it. A 404 here would mean the catch-all
        is shadowing real endpoints.
        """
        resp = self.client.get("/api/v1/customers/")
        self.assertEqual(resp.status_code, 401, resp.content)

    def test_non_api_routes_keep_django_html_404(self):
        """The catch-all is scoped to /api/v1/ only."""
        resp = self.client.get("/this-page-does-not-exist/")
        self.assertEqual(resp.status_code, 404)
        self.assertIn("text/html", resp["Content-Type"])

    @override_settings(DEBUG=False)
    def test_json_404_does_not_leak_debug_details(self):
        resp = self.client.get("/api/v1/still-not-a-route/")
        self.assertEqual(resp.status_code, 404)
        self.assertNotIn(b"Traceback", resp.content)
        self.assertNotIn(b"DEBUG", resp.content)
