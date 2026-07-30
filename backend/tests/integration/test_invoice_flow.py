from django.utils import timezone
from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.customers.models import Customer
from apps.venues.models import Venue
from apps.bookings.models import Booking
from apps.invoices.models import Invoice


class TestInvoiceFlow(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Test Venue", owner_name="Owner",
            email="test@test.com", mobile="9999999999",
        )
        self.user = User.objects.create_user(
            email="admin@test.com", password="testpass123",
            full_name="Admin", tenant=self.tenant, role="OWNER",
        )
        self.client.force_authenticate(user=self.user)
        self.customer = Customer.objects.create(
            tenant=self.tenant, full_name="John Doe",
            mobile="8888888888",
        )
        self.venue = Venue.objects.create(
            tenant=self.tenant, name="Grand Hall",
            venue_type="BANQUET_HALL", capacity=200,
            weekday_price=50000, weekend_price=75000,
        )
        self.booking = Booking.objects.create(
            tenant=self.tenant,
            booking_number="VF-2026-000001",
            venue=self.venue, customer=self.customer,
            event_type="WEDDING",
            event_date=timezone.now().date(),
            guest_count=100, total_amount=100000,
            advance_amount=50000, status="CONFIRMED",
        )

    def test_create_and_generate_invoice(self):
        response = self.client.post("/api/v1/invoices/", {
            "booking": self.booking.id,
            "invoice_date": timezone.now().date().isoformat(),
            "subtotal": 100000,
            "total_amount": 118000,
        })
        self.assertEqual(response.status_code, 201)
        invoice_id = response.data["id"]

        response = self.client.get(f"/api/v1/invoices/{invoice_id}/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("invoice_number", response.data)

    def test_generate_from_booking(self):
        response = self.client.post("/api/v1/invoices/generate/", {
            "booking_id": self.booking.id,
        })
        self.assertEqual(response.status_code, 201)

        invoice = Invoice.objects.filter(booking=self.booking).first()
        self.assertIsNotNone(invoice)
        self.assertIsNotNone(invoice.invoice_number)

    def test_list_invoices(self):
        Invoice.objects.create(
            tenant=self.tenant, booking=self.booking,
            invoice_number="INV-2026-000001",
            invoice_date=timezone.now().date(),
            subtotal=100000, total_amount=118000,
        )
        response = self.client.get("/api/v1/invoices/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("results", response.data)
