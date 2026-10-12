"""Regression tests for QA-TEST-REPORT.md P1-2 (P1).

Two unhandled ``IntegrityError``s returned HTTP 500 with an HTML Django debug
page (leaking the schema) instead of a JSON 400:

1. ``Customer`` has ``unique_together = [("tenant", "mobile")]`` but nothing
   validated it before INSERT.
2. ``Invoice.invoice_number`` is ``unique`` and read-only with **no default**,
   so a direct ``POST /invoices/`` wrote ``""`` and the *second* create hit the
   unique constraint. (``core/exceptions.py`` now also maps any residual
   ``IntegrityError`` to a 400 as a backstop; these tests pin the proper
   field-level behaviour that should fire first.)
"""
from django.test import TransactionTestCase
from rest_framework.test import APITestCase, APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.tenants.models import Tenant
from apps.users.models import User
from apps.customers.models import Customer
from apps.bookings.models import Booking
from apps.invoices.models import Invoice
from apps.venues.models import Venue
from core.choices import UserRole, VenueType, VenueStatus, BookingStatus, EventType


def _auth_as(client, user):
    access = str(RefreshToken.for_user(user).access_token)
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")


class DuplicateMobileValidationTests(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Alpha Events", owner_name="Owner",
            email="alpha@test.com", mobile="9999999999", status="ACTIVE")
        self.owner = User.objects.create_user(
            email="owner@test.com", password="ownerpass123",
            full_name="Tenant Owner", tenant=self.tenant, role=UserRole.OWNER)
        _auth_as(self.client, self.owner)

    def test_duplicate_mobile_in_same_tenant_is_400_not_500(self):
        first = self.client.post(
            "/api/v1/customers/",
            {"full_name": "First", "mobile": "8888888888"}, format="json")
        self.assertEqual(first.status_code, 201, first.data)

        second = self.client.post(
            "/api/v1/customers/",
            {"full_name": "Second", "mobile": "8888888888"}, format="json")
        self.assertEqual(second.status_code, 400, second.data)
        self.assertIn("mobile", second.data.get("errors", second.data))
        # no second row was written
        self.assertEqual(
            Customer.objects.filter(mobile="8888888888").count(), 1)

    def test_same_mobile_allowed_in_a_different_tenant(self):
        other = Tenant.objects.create(
            business_name="Beta Events", owner_name="B",
            email="beta@test.com", mobile="8888111122", status="ACTIVE")
        Customer.objects.create(
            tenant=other, full_name="Other Tenant", mobile="7777777777")
        response = self.client.post(
            "/api/v1/customers/",
            {"full_name": "Alpha Twin", "mobile": "7777777777"}, format="json")
        self.assertEqual(response.status_code, 201, response.data)

    def test_updating_to_a_taken_mobile_is_400(self):
        Customer.objects.create(
            tenant=self.tenant, full_name="Taken", mobile="6666666666")
        target = Customer.objects.create(
            tenant=self.tenant, full_name="Target", mobile="5555555555")
        response = self.client.patch(
            f"/api/v1/customers/{target.id}/",
            {"mobile": "6666666666"}, format="json")
        self.assertEqual(response.status_code, 400, response.data)


class InvoiceNumberGenerationTests(TransactionTestCase):
    """Sequential invoice numbers are generated on the direct create path.

    ``TransactionTestCase`` because a rejected create trips a unique
    constraint, which marks ``TestCase``'s per-test atomic for rollback and
    would mask the assertion with ``TransactionManagementError``.
    """

    def setUp(self):
        self.client = APIClient()
        self.tenant = Tenant.objects.create(
            business_name="Alpha Events", owner_name="Owner",
            email="alpha@test.com", mobile="9999999999", status="ACTIVE")
        self.owner = User.objects.create_user(
            email="owner@test.com", password="ownerpass123",
            full_name="Tenant Owner", tenant=self.tenant, role=UserRole.OWNER)
        self.venue = Venue.objects.create(
            tenant=self.tenant, name="Hall", venue_type=VenueType.BANQUET_HALL,
            capacity=200, status=VenueStatus.ACTIVE)
        self.customer = Customer.objects.create(
            tenant=self.tenant, full_name="Cust", mobile="4444444444")
        self.booking = Booking.objects.create(
            tenant=self.tenant, venue=self.venue, customer=self.customer,
            event_type=EventType.WEDDING, event_date="2027-02-01",
            guest_count=50, total_amount=40000, status=BookingStatus.DRAFT)
        _auth_as(self.client, self.owner)

    def _create_invoice(self):
        return self.client.post(
            "/api/v1/invoices/",
            {"booking": self.booking.id, "invoice_date": "2026-01-15",
             "subtotal": 40000, "tax_amount": 0, "total_amount": 40000},
            format="json")

    def test_direct_create_generates_a_non_empty_unique_number(self):
        first = self._create_invoice()
        self.assertEqual(first.status_code, 201, first.data)
        self.assertTrue(first.data["invoice_number"],
                        "invoice_number must not be empty")

        second = self._create_invoice()
        self.assertEqual(second.status_code, 201, second.data)
        self.assertTrue(second.data["invoice_number"])
        self.assertNotEqual(first.data["invoice_number"],
                            second.data["invoice_number"])

    def test_numbers_are_sequential_per_year(self):
        a = self._create_invoice()
        b = self._create_invoice()
        self.assertEqual(a.status_code, 201, a.data)
        self.assertEqual(b.status_code, 201, b.data)
        self.assertEqual(
            int(b.data["invoice_number"].rsplit("-", 1)[-1]),
            int(a.data["invoice_number"].rsplit("-", 1)[-1]) + 1)

    def test_generator_tolerates_legacy_empty_rows(self):
        # A legacy row with the old "" default must not crash the generator.
        Invoice.objects.create(
            tenant=self.tenant, booking=self.booking, invoice_number="",
            invoice_date="2026-01-01")
        response = self._create_invoice()
        self.assertEqual(response.status_code, 201, response.data)
        self.assertTrue(response.data["invoice_number"])
