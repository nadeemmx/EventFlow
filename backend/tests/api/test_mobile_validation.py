"""Regression tests for QA-TEST-REPORT-ROLES.md F-5 (P2).

``core/validators.py::validate_mobile`` existed but was wired to nothing — no
serializer and no model used it — so any string up to ``max_length`` was
accepted and stored. ``"mobile": "not-a-number-mgr"`` came back **201**.

The fix wires that validator into every serializer exposing ``mobile``.

The accepted pattern deliberately mirrors the frontend zod rule rather than the
unused E.164 regex that sat beside it: the UI submits the number as typed
(spaces, dashes, parentheses, no normalisation), so the backend has to accept
at least everything the UI accepts or it rejects its own product's input.

Real JWTs are minted rather than using ``force_authenticate``, which bypasses
``TenantJWTAuthentication`` and therefore leaves ``request.tenant`` unset —
these viewsets call ``serializer.save(tenant=self.request.tenant)``.
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.customers.models import Customer
from apps.tenants.models import Tenant
from apps.users.models import User
from core.choices import UserRole


class MobileFormatValidationTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.tenant = Tenant.objects.create(
            business_name="Alpha Events", owner_name="Owner",
            email="alpha@test.com", mobile="9999999999", status="ACTIVE")
        self.owner = User.objects.create_user(
            email="owner@test.com", password="ownerpass123",
            full_name="Tenant Owner", tenant=self.tenant, role=UserRole.OWNER)
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer "
                               f"{RefreshToken.for_user(self.owner).access_token}")

    def test_the_bugged_payload_now_returns_400(self):
        """The exact payload from the QA report."""
        resp = self.client.post(
            "/api/v1/customers/",
            {"full_name": "Bad Mobile", "mobile": "not-a-number-mgr"},
            format="json")
        self.assertEqual(resp.status_code, 400, resp.data)
        self.assertIn("mobile", resp.data["errors"])

    def test_letters_and_junk_rejected_across_resources(self):
        junk = "not-a-number-mgr"
        cases = [
            ("/api/v1/customers/",
             {"full_name": "C1", "mobile": junk}),
            ("/api/v1/staff/",
             {"name": "S1", "mobile": junk}),
            ("/api/v1/vendors/",
             {"name": "V1", "vendor_type": "CATERER", "mobile": junk}),
        ]
        for url, payload in cases:
            with self.subTest(url=url):
                resp = self.client.post(url, payload, format="json")
                self.assertEqual(resp.status_code, 400, resp.data)
                self.assertIn("mobile", resp.data["errors"])

    def test_formats_the_ui_accepts_are_still_accepted(self):
        """The backend must not reject its own frontend's valid input."""
        accepted = [
            "9876543210",
            "+919876543210",
            "+91 98765 43210",
            "(987) 654-3210",
            "98765-43210",
        ]
        for i, mobile in enumerate(accepted):
            with self.subTest(mobile=mobile):
                resp = self.client.post(
                    "/api/v1/customers/",
                    {"full_name": f"C{i}", "mobile": mobile}, format="json")
                self.assertEqual(resp.status_code, 201, resp.data)
                self.assertEqual(
                    Customer.objects.get(pk=resp.data["id"]).mobile, mobile)

    def test_too_short_and_too_long_rejected(self):
        for mobile in ("123456", "9" * 16):
            with self.subTest(mobile=mobile):
                resp = self.client.post(
                    "/api/v1/customers/",
                    {"full_name": "C2", "mobile": mobile}, format="json")
                self.assertEqual(resp.status_code, 400, resp.data)
                self.assertIn("mobile", resp.data["errors"])

    def test_blank_optional_mobile_still_allowed(self):
        """No regression on optional mobiles (users, profile, register)."""
        resp = self.client.post(
            "/api/v1/users/",
            {"full_name": "No Mobile", "email": "nomobile@test.com",
             "password": "Str0ng!Pass1", "role": "STAFF", "mobile": ""},
            format="json")
        self.assertEqual(resp.status_code, 201, resp.data)

    def test_registration_rejects_bad_mobile(self):
        anon = APIClient()
        resp = anon.post(
            "/api/v1/auth/register/",
            {"full_name": "New Owner", "email": "newowner@test.com",
             "password": "Str0ng!Pass1", "confirm_password": "Str0ng!Pass1",
             "mobile": "not-a-number"},
            format="json")
        self.assertEqual(resp.status_code, 400, resp.data)
        self.assertIn("mobile", resp.data["errors"])
