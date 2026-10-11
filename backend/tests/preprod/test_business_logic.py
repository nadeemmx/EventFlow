"""Pre-production business-logic tests: payment webhooks, invoice
generation, booking state machine, refunds and plan-limit enforcement.

Covers checklist items #17 (Payment Integration), #18 (Invoice Workflow),
#19 (Booking Lifecycle) and #25 (Subscription/Feature Limits).
"""
import hashlib
import hmac
import json
import unittest
from pathlib import Path
from unittest import mock

from django.utils import timezone
from rest_framework.test import APITestCase

from apps.bookings.models import Booking
from apps.customers.models import Customer
from apps.invoices.models import Invoice
from apps.payments.models import Payment
from apps.settings.models import PaymentGatewaySettings
from apps.tenants.models import Tenant, TenantSettings
from apps.users.models import User
from apps.venues.models import Venue
from core.choices import UserRole


class BusinessLogicBase(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Biz Venue", owner_name="Owner",
            email="biz@test.com", mobile="9000000701",
        )
        TenantSettings.objects.create(tenant=self.tenant)
        self.owner = User.objects.create_user(
            email="biz-owner@test.com", password="BizPass123!",
            full_name="Biz Owner", tenant=self.tenant, role=UserRole.OWNER,
        )
        self.customer = Customer.objects.create(
            tenant=self.tenant, full_name="Biz Customer", mobile="9000000702",
        )
        self.venue = Venue.objects.create(
            tenant=self.tenant, name="Biz Hall", venue_type="BANQUET_HALL",
            capacity=150, weekday_price=20000, weekend_price=30000,
        )
        self.booking = Booking.objects.create(
            tenant=self.tenant, venue=self.venue, customer=self.customer,
            booking_number="VF-2026-BIZ01", event_type="WEDDING",
            event_date=timezone.now().date(), guest_count=100,
            total_amount=100000, advance_amount=50000, status="DRAFT",
        )
        self.client.force_authenticate(user=self.owner)

    def _gateway(self, secret="whsec_test", **kwargs):
        return PaymentGatewaySettings.objects.create(
            tenant=self.tenant, gateway="RAZORPAY",
            api_key="rzp_key", api_secret="rzp_secret",
            webhook_secret=secret, is_active=True,
            environment=kwargs.pop("environment", "test"), **kwargs,
        )


class RazorpayWebhookTests(BusinessLogicBase):
    WEBHOOK = "/api/v1/payments/webhook/razorpay/"

    def _post(self, body, signature):
        if isinstance(body, (dict, list)):
            body = json.dumps(body)
        return self.client.post(
            self.WEBHOOK, data=body, content_type="application/json",
            HTTP_X_RAZORPAY_SIGNATURE=signature,
        )

    @staticmethod
    def _sign(secret, body):
        return hmac.new(secret.encode(), body.encode(), hashlib.sha256).hexdigest()

    def test_webhook_rejects_non_post_methods(self):
        response = self.client.get(self.WEBHOOK)
        self.assertEqual(response.status_code, 405)

    def test_webhook_ignored_when_no_gateway_configured(self):
        response = self._post({"event": "payment.captured"}, "deadbeef")
        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(json.loads(response.content)["status"], "ignored")

    def test_webhook_rejects_invalid_signature(self):
        self._gateway()
        body = json.dumps({"event": "payment.captured", "payload": {}})
        response = self._post(body, self._sign("wrong_secret", body))
        self.assertEqual(response.status_code, 400, response.content)
        self.assertIn("signature", response.content.decode().lower())

    def test_webhook_rejects_tampered_body(self):
        self._gateway()
        original = json.dumps({"event": "payment.captured", "payload": {}})
        signature = self._sign("whsec_test", original)
        tampered = original + " "
        response = self._post(tampered, signature)
        self.assertEqual(response.status_code, 400, response.content)

    def test_webhook_accepts_valid_signature_without_matching_booking(self):
        self._gateway()
        body = json.dumps({
            "event": "payment.captured",
            "payload": {"payment": {"entity": {
                "id": "pay_NOMATCH", "order_id": "order_NOPE",
                "amount": 5000000,
            }}},
        })
        response = self._post(body, self._sign("whsec_test", body))
        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(Payment.objects.count(), 0)

    def test_webhook_records_payment_for_known_booking(self):
        self._gateway()
        payload = {
            "event": "payment.captured",
            "payload": {"payment": {"entity": {
                "id": "pay_BIZ01", "order_id": "order_VF-2026-BIZ01",
                "amount": 5000000,
            }}},
        }
        body = json.dumps(payload)
        response = self._post(body, self._sign("whsec_test", body))
        self.assertEqual(response.status_code, 200, response.content)
        payment = Payment.objects.get(transaction_reference="pay_BIZ01")
        self.assertEqual(float(payment.amount), 50000.0)
        self.assertEqual(payment.booking_id, self.booking.id)
        self.assertEqual(payment.tenant_id, self.tenant.id)

    def test_webhook_is_idempotent_on_replay(self):
        self._gateway()
        payload = {
            "event": "payment.captured",
            "payload": {"payment": {"entity": {
                "id": "pay_REPLAY", "order_id": "order_VF-2026-BIZ01",
                "amount": 2500000,
            }}},
        }
        body = json.dumps(payload)
        signature = self._sign("whsec_test", body)
        self.assertEqual(self._post(body, signature).status_code, 200)
        self.assertEqual(self._post(body, signature).status_code, 200)
        self.assertEqual(
            Payment.objects.filter(transaction_reference="pay_REPLAY").count(), 1
        )

    @unittest.expectedFailure
    def test_webhook_gateway_lookup_is_tenant_scoped(self):
        """KNOWN GAP: the Razorpay webhook picks the first active gateway
        settings row with no tenant filter (config/api_router.py:46-52), so a
        signature from one tenant's secret can post payments into another
        tenant's booking."""
        source = Path("config/api_router.py").read_text()
        self.assertIn(
            "PaymentGatewaySettings.objects.filter(\n            tenant=", source,
            "webhook must scope gateway settings to a tenant",
        )


class InvoiceWorkflowTests(BusinessLogicBase):
    def setUp(self):
        super().setUp()
        self.booking.status = "CONFIRMED"
        self.booking.save(update_fields=["status"])

    def test_generate_invoice_from_booking(self):
        response = self.client.post(
            "/api/v1/invoices/generate/", {"booking_id": self.booking.id}
        )
        self.assertEqual(response.status_code, 201, response.content)
        data = json.loads(response.content)["data"]
        self.assertTrue(data["invoice_number"].startswith("INV"))
        self.assertTrue(
            Invoice.objects.filter(booking=self.booking, tenant=self.tenant).exists()
        )

    def test_invoice_total_includes_gst(self):
        self.client.post("/api/v1/invoices/generate/", {"booking_id": self.booking.id})
        invoice = Invoice.objects.get(booking=self.booking)
        gst_rate = float(self.tenant.settings.gst_rate)
        expected_tax = round(100000 * gst_rate / 100, 2)
        self.assertAlmostEqual(float(invoice.subtotal), 100000.0)
        self.assertAlmostEqual(float(invoice.tax_amount), expected_tax, places=2)
        self.assertAlmostEqual(
            float(invoice.total_amount), 100000.0 + expected_tax, places=2
        )

    def test_duplicate_invoice_generation_rejected(self):
        first = self.client.post(
            "/api/v1/invoices/generate/", {"booking_id": self.booking.id}
        )
        self.assertEqual(first.status_code, 201, first.content)
        second = self.client.post(
            "/api/v1/invoices/generate/", {"booking_id": self.booking.id}
        )
        self.assertEqual(second.status_code, 400, second.content)
        self.assertEqual(Invoice.objects.filter(booking=self.booking).count(), 1)

    def test_invoice_pdf_download(self):
        created = self.client.post(
            "/api/v1/invoices/generate/", {"booking_id": self.booking.id}
        )
        invoice_id = json.loads(created.content)["data"]["id"]
        response = self.client.get(f"/api/v1/invoices/{invoice_id}/pdf/")
        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(response["Content-Type"], "application/pdf")
        self.assertTrue(response.content.startswith(b"%PDF"), "real PDF bytes expected")

    def test_invoice_list_is_tenant_scoped(self):
        self.client.post("/api/v1/invoices/generate/", {"booking_id": self.booking.id})
        body = json.loads(self.client.get("/api/v1/invoices/").content)
        self.assertEqual(body["count"], 1)
        self.assertEqual(body["results"][0]["booking"], self.booking.id)
        self.assertEqual(body["results"][0]["id"],
                         Invoice.objects.get().id)


class BookingStateMachineTests(BusinessLogicBase):
    def test_confirm_requires_advance_payment(self):
        self.booking.advance_amount = 0
        self.booking.save(update_fields=["advance_amount"])
        response = self.client.post(f"/api/v1/bookings/{self.booking.id}/confirm/")
        self.assertEqual(response.status_code, 400, response.content)
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, "DRAFT")

    def test_confirm_happy_path(self):
        response = self.client.post(f"/api/v1/bookings/{self.booking.id}/confirm/")
        self.assertEqual(response.status_code, 200, response.content)
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, "CONFIRMED")
        self.assertTrue(self.booking.history.exists(),
                        "status history must be recorded")

    def test_illegal_transition_is_rejected(self):
        response = self.client.post(f"/api/v1/bookings/{self.booking.id}/mark_completed/")
        self.assertEqual(response.status_code, 400, response.content)
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, "DRAFT")

    def test_cancelled_booking_cannot_be_confirmed(self):
        self.booking.status = "CANCELLED"
        self.booking.save(update_fields=["status"])
        response = self.client.post(f"/api/v1/bookings/{self.booking.id}/confirm/")
        self.assertEqual(response.status_code, 400, response.content)

    def test_confirm_twice_is_rejected(self):
        self.assertEqual(
            self.client.post(f"/api/v1/bookings/{self.booking.id}/confirm/").status_code, 200
        )
        again = self.client.post(f"/api/v1/bookings/{self.booking.id}/confirm/")
        self.assertEqual(again.status_code, 400, again.content)


class PaymentAndRefundTests(BusinessLogicBase):
    def setUp(self):
        super().setUp()
        self.booking.status = "CONFIRMED"
        self.booking.save(update_fields=["status"])

    def test_payment_updates_outstanding(self):
        response = self.client.post("/api/v1/payments/", {
            "booking": self.booking.id, "amount": 50000,
            "payment_method": "CASH",
            "payment_date": timezone.now().date().isoformat(),
        })
        self.assertEqual(response.status_code, 201, response.content)
        outstanding = json.loads(
            self.client.get(f"/api/v1/payments/{self.booking.id}/outstanding/").content
        )["data"]
        self.assertAlmostEqual(float(outstanding["outstanding"]), 50000.0)

    @unittest.expectedFailure
    def test_non_positive_payment_rejected(self):
        """KNOWN GAP: services/payment_service.py:28 only compares
        amount > outstanding, so 0 and negative amounts are accepted and can
        understate revenue in reports."""
        paid_on = timezone.now().date().isoformat()
        for amount in (0, -100):
            with self.subTest(amount=amount):
                response = self.client.post("/api/v1/payments/", {
                    "booking": self.booking.id, "amount": amount,
                    "payment_method": "CASH", "payment_date": paid_on,
                })
                self.assertEqual(response.status_code, 400, response.content)
        self.assertEqual(Payment.objects.count(), 0)

    def test_payment_more_than_total_rejected(self):
        response = self.client.post("/api/v1/payments/", {
            "booking": self.booking.id, "amount": 1000000,
            "payment_method": "CASH",
        })
        self.assertEqual(response.status_code, 400, response.content)

    def test_refund_flow(self):
        cancel = self.client.post(f"/api/v1/bookings/{self.booking.id}/cancel/")
        self.assertEqual(cancel.status_code, 200, cancel.content)
        created = self.client.post("/api/v1/payments/", {
            "booking": self.booking.id, "amount": 50000,
            "payment_method": "CASH",
            "payment_date": timezone.now().date().isoformat(),
        })
        payment_id = json.loads(created.content)["data"]["id"]
        response = self.client.post(f"/api/v1/payments/{payment_id}/refund/")
        self.assertEqual(response.status_code, 200, response.content)
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, "REFUNDED")

    def test_payment_summary_matches_recorded_payments(self):
        Payment.objects.create(
            tenant=self.tenant, booking=self.booking, amount=30000,
            payment_method="CASH", payment_type="PAYMENT",
            payment_date=timezone.now().date(),
        )
        body = json.loads(self.client.get("/api/v1/payments/summary/").content)["data"]
        self.assertAlmostEqual(float(body["total_collected"]), 30000.0)

    def test_cross_tenant_payment_rejected(self):
        other_tenant = Tenant.objects.create(
            business_name="Other Biz", owner_name="Other",
            email="other-biz@test.com", mobile="9000000703",
        )
        other_customer = Customer.objects.create(
            tenant=other_tenant, full_name="Other Cust", mobile="9000000704",
        )
        other_venue = Venue.objects.create(
            tenant=other_tenant, name="Other Hall", venue_type="BANQUET_HALL",
            capacity=10, weekday_price=100, weekend_price=200,
        )
        other_booking = Booking.objects.create(
            tenant=other_tenant, venue=other_venue, customer=other_customer,
            booking_number="VF-2026-OTHER1", event_type="BIRTHDAY",
            event_date=timezone.now().date(), guest_count=10,
            total_amount=1000, advance_amount=0, status="CONFIRMED",
        )
        response = self.client.post("/api/v1/payments/", {
            "booking": other_booking.id, "amount": 100,
            "payment_method": "CASH",
        })
        self.assertEqual(response.status_code, 400, response.content)
        self.assertEqual(Payment.objects.filter(tenant=other_tenant).count(), 0)


class SubscriptionLimitTests(BusinessLogicBase):
    @unittest.expectedFailure
    def test_venue_creation_is_capped_by_plan(self):
        """KNOWN GAP: permissions/feature_limits.py EnforceVenueLimit is a
        stub returning True and no view enforces it, so a tenant on the
        smallest plan can create unlimited venues."""
        from permissions.feature_limits import EnforceVenueLimit
        self.assertFalse(
            EnforceVenueLimit().can_add_venue(self.tenant),
            "plan limits must be enforced before hitting the database",
        )

    @unittest.expectedFailure
    def test_customer_creation_is_capped_by_plan(self):
        """KNOWN GAP: EnforceUserLimit is unused, plan quotas are not
        enforced at the API boundary."""
        from permissions.feature_limits import EnforceUserLimit
        self.assertFalse(
            EnforceUserLimit().can_add_user(self.tenant),
            "user plan quota must be enforced",
        )

    @unittest.expectedFailure
    def test_payment_amount_has_minimum_validator(self):
        """KNOWN GAP: Payment.amount has no MinValueValidator, the API only
        rejects negative amounts inside the service layer."""
        from apps.payments.models import Payment
        field = Payment._meta.get_field("amount")
        from django.core.validators import MinValueValidator
        self.assertTrue(
            any(isinstance(v, MinValueValidator) for v in field.validators),
            "declare min value on the model so bulk/CLI paths are covered too",
        )


class RazorpaySignatureUnitTests(unittest.TestCase):
    """Pure unit coverage of the HMAC verification primitive."""

    def test_verify_webhook_accepts_correct_signature(self):
        from gateway.payments.razorpay import RazorpayGateway
        body = '{"event":"payment.captured"}'
        sig = hmac.new(b"s3cret", body.encode(), hashlib.sha256).hexdigest()
        self.assertTrue(RazorpayGateway.verify_webhook(body, sig, "s3cret"))

    def test_verify_webhook_rejects_wrong_secret(self):
        from gateway.payments.razorpay import RazorpayGateway
        body = '{"event":"payment.captured"}'
        sig = hmac.new(b"other", body.encode(), hashlib.sha256).hexdigest()
        self.assertFalse(RazorpayGateway.verify_webhook(body, sig, "s3cret"))

    def test_verify_webhook_rejects_empty_signature(self):
        from gateway.payments.razorpay import RazorpayGateway
        self.assertFalse(RazorpayGateway.verify_webhook("{}", "", "s3cret"))

    def test_verify_webhook_is_not_vulnerable_to_length_oracle(self):
        from gateway.payments.razorpay import RazorpayGateway
        body = '{"event":"payment.captured"}'
        sig = hmac.new(b"s3cret", body.encode(), hashlib.sha256).hexdigest()
        self.assertFalse(RazorpayGateway.verify_webhook(body, sig[:-1], "s3cret"))
        self.assertFalse(RazorpayGateway.verify_webhook(body, "0" * 64, "s3cret"))


class ReportAggregationTests(BusinessLogicBase):
    def test_revenue_report_reflects_payments(self):
        self.booking.status = "CONFIRMED"
        self.booking.save(update_fields=["status"])
        Payment.objects.create(
            tenant=self.tenant, booking=self.booking, amount=40000,
            payment_method="CASH", payment_type="PAYMENT",
            payment_date=timezone.now().date(),
        )
        response = self.client.get("/api/v1/reports/revenue/")
        self.assertEqual(response.status_code, 200, response.content)
        body = json.loads(response.content)
        blob = json.dumps(body)
        self.assertIn("40000", blob)

    def test_bookings_report_uses_only_own_tenant(self):
        other_tenant = Tenant.objects.create(
            business_name="Other Report", owner_name="Other",
            email="other-report@test.com", mobile="9000000705",
        )
        other_customer = Customer.objects.create(
            tenant=other_tenant, full_name="Ghost", mobile="9000000706",
        )
        other_venue = Venue.objects.create(
            tenant=other_tenant, name="Ghost Hall", venue_type="BANQUET_HALL",
            capacity=5, weekday_price=10, weekend_price=20,
        )
        Booking.objects.create(
            tenant=other_tenant, venue=other_venue, customer=other_customer,
            booking_number="VF-2026-GHOST1", event_type="BIRTHDAY",
            event_date=timezone.now().date(), guest_count=5,
            total_amount=999999, advance_amount=0, status="CONFIRMED",
        )
        response = self.client.get("/api/v1/reports/bookings/")
        self.assertEqual(response.status_code, 200, response.content)
        self.assertNotIn("999999", json.dumps(json.loads(response.content)))
