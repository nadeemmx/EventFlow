"""Pre-production audit-logging and privacy/GDPR compliance tests.

Covers checklist items #26 (Audit Logging) and #30 (Privacy/GDPR
compliance: request intake, reference tracking, tenant-scoped review).
"""
import json
import unittest
from unittest import mock

from django.core import mail
from django.utils import timezone
from rest_framework.test import APITestCase

from apps.audit_logs.models import AuditLog
from apps.customers.models import Customer
from apps.privacy.models import PrivacyRequest
from apps.tenants.models import Tenant, TenantSettings
from apps.users.models import User
from apps.venues.models import Venue
from core.choices import UserRole


class AuditLoggingTests(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Audit Venue", owner_name="Owner",
            email="audit@test.com", mobile="9000000501",
        )
        TenantSettings.objects.create(tenant=self.tenant)
        self.user = User.objects.create_user(
            email="audit-owner@test.com", password="AuditPass123!",
            full_name="Audit Owner", tenant=self.tenant, role=UserRole.OWNER,
        )
        self.customer = Customer.objects.create(
            tenant=self.tenant, full_name="Audit Customer", mobile="9000000502",
        )
        self.venue = Venue.objects.create(
            tenant=self.tenant, name="Audit Hall", venue_type="BANQUET_HALL",
            capacity=80, weekday_price=1000, weekend_price=2000,
        )

    def test_login_writes_auth_audit_row_with_ip(self):
        response = self.client.post("/api/v1/auth/login/", {
            "email": "audit-owner@test.com", "password": "AuditPass123!",
        }, format="json")
        self.assertEqual(response.status_code, 200, response.content)
        row = AuditLog.objects.filter(
            module="AUTH", action="LOGIN", user=self.user, tenant=self.tenant
        ).order_by("-created_at").first()
        self.assertIsNotNone(row, "login must be audited")
        self.assertTrue(row.ip_address, "login audit must capture client IP")

    def test_logout_writes_auth_audit_row(self):
        login = self.client.post("/api/v1/auth/login/", {
            "email": "audit-owner@test.com", "password": "AuditPass123!",
        }, format="json")
        self.assertEqual(login.status_code, 200, login.content)
        tokens = json.loads(login.content)["data"]
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {tokens['access_token']}")
        response = self.client.post(
            "/api/v1/auth/logout/", {"refresh_token": tokens["refresh_token"]}
        )
        self.assertEqual(response.status_code, 200, response.content)
        self.assertTrue(
            AuditLog.objects.filter(
                module="AUTH", action="LOGOUT", user=self.user, tenant=self.tenant
            ).exists(),
            "logout must be audited",
        )

    def test_booking_create_and_status_change_are_audited(self):
        self.client.force_authenticate(user=self.user)
        event_date = str(timezone.now().date() + timezone.timedelta(days=45))
        response = self.client.post("/api/v1/bookings/", {
            "venue": self.venue.id,
            "customer": self.customer.id,
            "event_type": "WEDDING",
            "event_date": event_date,
            "guest_count": 50,
            "total_amount": 150000,
            "advance_amount": 25000,
        })
        self.assertEqual(response.status_code, 201, response.content)
        payload = json.loads(response.content)
        booking_id = payload.get("data", payload).get("id")

        create_rows = AuditLog.objects.filter(
            module="BOOKINGS", action="CREATE", record_id=booking_id
        )
        self.assertTrue(create_rows.exists(), "booking creation must be audited")
        row = create_rows.first()
        self.assertEqual(row.tenant_id, self.tenant.id)
        self.assertEqual(row.user_id, self.user.id)

        confirm = self.client.post(f"/api/v1/bookings/{booking_id}/confirm/")
        self.assertEqual(confirm.status_code, 200, confirm.content)
        self.assertTrue(
            AuditLog.objects.filter(
                module="BOOKINGS", action="CONFIRM", record_id=booking_id
            ).exists(),
            "booking confirm must be audited with old/new status",
        )

    def test_payment_create_is_audited(self):
        from apps.bookings.models import Booking
        booking = Booking.objects.create(
            tenant=self.tenant, venue=self.venue, customer=self.customer,
            booking_number="VF-2026-AUDIT1", event_type="CORPORATE",
            event_date=timezone.now().date(), guest_count=50,
            total_amount=50000, advance_amount=0, status="CONFIRMED",
        )
        self.client.force_authenticate(user=self.user)
        response = self.client.post("/api/v1/payments/", {
            "booking": booking.id, "amount": 50000,
            "payment_method": "CASH", "payment_type": "FULL",
            "payment_date": timezone.now().date().isoformat(),
        })
        self.assertIn(response.status_code, (200, 201), response.content)
        self.assertTrue(
            AuditLog.objects.filter(module="PAYMENTS", action="CREATE").exists(),
            "payment recording must be audited",
        )

    def test_audit_rows_never_store_password_material(self):
        self.client.force_authenticate(user=self.user)
        self.client.post("/api/v1/auth/login/", {
            "email": "audit-owner@test.com", "password": "AuditPass123!",
        }, format="json")
        for row in AuditLog.objects.all():
            blob = f"{row.old_data} {row.new_data} {row.action} {row.module}"
            self.assertNotIn("AuditPass123!", blob)
            self.assertNotIn("password", blob.lower())

    @unittest.expectedFailure
    def test_customer_create_writes_audit_trail(self):
        """KNOWN GAP: customer creation writes no audit row.

        Only MERGE is audited (services/customer_service.py:29); CREATE is
        missing. Remove the expectedFailure marker once fixed.
        """
        self.client.force_authenticate(user=self.user)
        before = AuditLog.objects.filter(module="CUSTOMERS").count()
        response = self.client.post("/api/v1/customers/", {
            "full_name": "Fresh Customer", "mobile": "9000000503",
        })
        self.assertIn(response.status_code, (200, 201), response.content)
        after = AuditLog.objects.filter(module="CUSTOMERS").count()
        self.assertGreater(after, before, "customer create must be audited")


class PrivacyComplianceTests(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Privacy Venue", owner_name="Owner",
            email="privacy@test.com", mobile="9000000601",
        )
        TenantSettings.objects.create(tenant=self.tenant)
        self.owner = User.objects.create_user(
            email="privacy-owner@test.com", password="PrivacyPass123!",
            full_name="Privacy Owner", tenant=self.tenant, role=UserRole.OWNER,
        )

    def test_anonymous_privacy_request_is_accepted_with_reference(self):
        response = self.client.post("/api/v1/privacy/submit/", {
            "email": "citizen@example.com",
            "full_name": "Data Citizen",
            "request_type": "PORTABILITY",
            "description": "Please send me a copy of my data.",
            "privacy_acknowledged": True,
        }, format="json")
        self.assertIn(response.status_code, (200, 201), response.content)
        body = json.loads(response.content)
        data = body.get("data", body)
        self.assertRegex(data["reference"], r"^PR-\d{6}$")
        self.assertEqual(data["status"], PrivacyRequest.Status.SUBMITTED)
        self.assertTrue(
            PrivacyRequest.objects.filter(email="citizen@example.com").exists()
        )

    def test_privacy_request_sends_confirmation_email(self):
        with self.settings(EMAIL_BACKEND="django.core.mail.backends.locmem.EmailBackend"):
            response = self.client.post("/api/v1/privacy/submit/", {
                "email": "citizen-two@example.com",
                "request_type": "ERASURE",
                "privacy_acknowledged": True,
            }, format="json")
            self.assertIn(response.status_code, (200, 201), response.content)
        self.assertTrue(mail.outbox, "confirmation email must be sent")
        self.assertIn("privacy request received", mail.outbox[0].subject.lower())

    def test_privacy_request_rejects_invalid_input(self):
        cases = [
            {"email": "not-an-email", "request_type": "PORTABILITY"},
            {"email": "ok@example.com", "request_type": "NOT_A_TYPE"},
            {"request_type": "PORTABILITY"},
        ]
        for payload in cases:
            with self.subTest(payload=payload):
                response = self.client.post("/api/v1/privacy/submit/", payload, format="json")
                self.assertEqual(response.status_code, 400, payload)

    @unittest.expectedFailure
    def test_privacy_request_requires_acknowledgement(self):
        """KNOWN GAP: the contact form enforces privacy_acknowledged but
        /privacy/submit/ accepts the field as optional
        (apps/privacy/serializers.py:9) and drops it."""
        response = self.client.post("/api/v1/privacy/submit/", {
            "email": "no-ack@example.com", "request_type": "PORTABILITY",
        }, format="json")
        self.assertEqual(response.status_code, 400, response.content)

    def test_owner_reviews_only_own_tenant_requests(self):
        other_tenant = Tenant.objects.create(
            business_name="Other Privacy", owner_name="Other",
            email="other-privacy@test.com", mobile="9000000602",
        )
        PrivacyRequest.objects.create(
            email="other@example.com", request_type="ERASURE",
            tenant=other_tenant, full_name="Other Tenant Citizen",
        )
        mine = PrivacyRequest.objects.create(
            email="mine@example.com", request_type="PORTABILITY",
            tenant=self.tenant, full_name="My Tenant Citizen",
        )
        self.client.force_authenticate(user=self.owner)
        body = json.loads(self.client.get("/api/v1/privacy/requests/").content)
        results = body["results"] if "results" in body else body
        emails = [row["email"] for row in results]
        self.assertIn("mine@example.com", emails)
        self.assertNotIn("other@example.com", emails)
        self.assertEqual(
            self.client.get(f"/api/v1/privacy/requests/{mine.id}/").status_code, 200
        )

    def test_owner_can_mark_request_actioned(self):
        request_row = PrivacyRequest.objects.create(
            email="close@example.com", request_type="PORTABILITY",
            tenant=self.tenant, full_name="Close Me",
        )
        self.client.force_authenticate(user=self.owner)
        response = self.client.patch(
            f"/api/v1/privacy/requests/{request_row.id}/",
            {"status": PrivacyRequest.Status.ACTIONED},
        )
        self.assertIn(response.status_code, (200, 204), response.content)
        request_row.refresh_from_db()
        self.assertEqual(request_row.status, PrivacyRequest.Status.ACTIONED)
        self.assertIsNotNone(request_row.responded_at)

    def test_contact_form_intake(self):
        response = self.client.post("/api/v1/contact/", {
            "source": "contact", "name": "Visitor", "email": "visitor@example.com",
            "subject": "Pricing", "message": "How much for 200 guests?",
            "privacy_acknowledged": True,
        }, format="json")
        self.assertIn(response.status_code, (200, 201), response.content)

    @mock.patch("apps.privacy.views.send_mail")
    def test_privacy_submission_survives_mail_failure(self, send_mail_mock):
        send_mail_mock.side_effect = RuntimeError("smtp down")
        response = self.client.post("/api/v1/privacy/submit/", {
            "email": "resilient@example.com", "request_type": "PORTABILITY",
            "privacy_acknowledged": True,
        }, format="json")
        self.assertIn(response.status_code, (200, 201), response.content)
        self.assertTrue(PrivacyRequest.objects.filter(email="resilient@example.com").exists())
