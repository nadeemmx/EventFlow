from django.utils import timezone
from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.customers.models import Customer
from apps.venues.models import Venue
from apps.bookings.models import Booking
from apps.payments.models import Payment


class TestPaymentsAPI(APITestCase):
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
            advance_amount=25000, status="CONFIRMED",
        )

    def test_create_payment(self):
        response = self.client.post("/api/v1/payments/", {
            "booking": self.booking.id,
            "amount": 25000,
            "payment_method": "CASH",
            "payment_date": timezone.now().date().isoformat(),
        })
        self.assertEqual(response.status_code, 201)

    def test_list_payments(self):
        Payment.objects.create(
            tenant=self.tenant, booking=self.booking,
            amount=25000, payment_method="CASH",
            payment_type="PAYMENT", payment_date=timezone.now().date(),
        )
        response = self.client.get("/api/v1/payments/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("results", response.data)

    def test_retrieve_payment(self):
        payment = Payment.objects.create(
            tenant=self.tenant, booking=self.booking,
            amount=25000, payment_method="CASH",
            payment_type="PAYMENT", payment_date=timezone.now().date(),
        )
        response = self.client.get(f"/api/v1/payments/{payment.id}/")
        self.assertEqual(response.status_code, 200)

    def test_outstanding(self):
        Payment.objects.create(
            tenant=self.tenant, booking=self.booking,
            amount=25000, payment_method="CASH",
            payment_type="PAYMENT", payment_date=timezone.now().date(),
        )
        response = self.client.get(f"/api/v1/payments/{self.booking.id}/outstanding/")
        self.assertEqual(response.status_code, 200)

    def test_summary(self):
        response = self.client.get("/api/v1/payments/summary/")
        self.assertEqual(response.status_code, 200)

    def test_tenant_isolation(self):
        other_tenant = Tenant.objects.create(
            business_name="Other", owner_name="Other",
            email="other@test.com", mobile="7777777777",
        )
        payment = Payment.objects.create(
            tenant=other_tenant, booking=self.booking,
            amount=25000, payment_method="CASH",
            payment_type="PAYMENT", payment_date=timezone.now().date(),
        )
        response = self.client.get(f"/api/v1/payments/{payment.id}/")
        self.assertEqual(response.status_code, 404)
