from django.utils import timezone
from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.customers.models import Customer
from apps.venues.models import Venue
from apps.bookings.models import Booking


class TestBookingsAPI(APITestCase):
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

    def _create_booking(self, **kwargs):
        defaults = dict(
            tenant=self.tenant, venue=self.venue, customer=self.customer,
            booking_number="VF-2026-000001", event_type="WEDDING",
            event_date=timezone.now().date(), guest_count=100,
            total_amount=100000, advance_amount=25000, status="DRAFT",
        )
        defaults.update(kwargs)
        return Booking.objects.create(**defaults)

    def test_create_booking(self):
        response = self.client.post("/api/v1/bookings/", {
            "venue": self.venue.id,
            "customer": self.customer.id,
            "event_type": "WEDDING",
            "event_date": str(timezone.now().date() + timezone.timedelta(days=30)),
            "guest_count": 100,
            "total_amount": 100000,
        })
        self.assertEqual(response.status_code, 201)

    def test_list_bookings(self):
        self._create_booking()
        response = self.client.get("/api/v1/bookings/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("results", response.data)

    def test_retrieve_booking(self):
        booking = self._create_booking()
        response = self.client.get(f"/api/v1/bookings/{booking.id}/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["booking_number"], "VF-2026-000001")

    def test_update_booking(self):
        booking = self._create_booking()
        response = self.client.patch(f"/api/v1/bookings/{booking.id}/", {"guest_count": 150})
        self.assertEqual(response.status_code, 200)
        booking.refresh_from_db()
        self.assertEqual(booking.guest_count, 150)

    def test_confirm_booking(self):
        booking = self._create_booking()
        response = self.client.post(f"/api/v1/bookings/{booking.id}/confirm/")
        self.assertEqual(response.status_code, 200)
        booking.refresh_from_db()
        self.assertEqual(booking.status, "CONFIRMED")

    def test_cancel_booking(self):
        booking = self._create_booking(status="CONFIRMED")
        response = self.client.post(f"/api/v1/bookings/{booking.id}/cancel/")
        self.assertEqual(response.status_code, 200)
        booking.refresh_from_db()
        self.assertEqual(booking.status, "CANCELLED")

    def test_mark_in_progress(self):
        booking = self._create_booking(status="CONFIRMED")
        response = self.client.post(f"/api/v1/bookings/{booking.id}/mark_in_progress/")
        self.assertEqual(response.status_code, 200)
        booking.refresh_from_db()
        self.assertEqual(booking.status, "IN_PROGRESS")

    def test_mark_completed(self):
        booking = self._create_booking(status="IN_PROGRESS")
        response = self.client.post(f"/api/v1/bookings/{booking.id}/mark_completed/")
        self.assertEqual(response.status_code, 200)
        booking.refresh_from_db()
        self.assertEqual(booking.status, "COMPLETED")

    def test_calendar(self):
        response = self.client.get("/api/v1/bookings/calendar/?month=6&year=2026")
        self.assertEqual(response.status_code, 200)

    def test_tenant_isolation(self):
        other_tenant = Tenant.objects.create(
            business_name="Other", owner_name="Other",
            email="other@test.com", mobile="7777777777",
        )
        booking = self._create_booking(tenant=other_tenant,
            booking_number="VF-2026-999999")
        response = self.client.get(f"/api/v1/bookings/{booking.id}/")
        self.assertEqual(response.status_code, 404)
