from django.utils import timezone
from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.bookings.models import Booking


class TestBookingFullFlow(APITestCase):
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

    def test_full_booking_lifecycle(self):
        customer_response = self.client.post("/api/v1/customers/", {
            "full_name": "Jane Smith",
            "mobile": "7777777777",
            "email": "jane@test.com",
        })
        self.assertEqual(customer_response.status_code, 201)
        customer_id = customer_response.data["id"]

        venue_response = self.client.post("/api/v1/venues/", {
            "name": "Test Venue",
            "venue_type": "BANQUET_HALL",
            "capacity": 200,
            "weekday_price": 50000,
            "weekend_price": 75000,
        })
        self.assertEqual(venue_response.status_code, 201)
        venue_id = venue_response.data["id"]

        event_date = str(timezone.now().date() + timezone.timedelta(days=30))
        booking_response = self.client.post("/api/v1/bookings/", {
            "venue": venue_id,
            "customer": customer_id,
            "event_type": "WEDDING",
            "event_date": event_date,
            "guest_count": 100,
            "total_amount": 100000,
            "advance_amount": 25000,
        })
        self.assertEqual(booking_response.status_code, 201)
        booking_id = booking_response.data["data"]["id"]

        confirm_response = self.client.post(f"/api/v1/bookings/{booking_id}/confirm/")
        self.assertEqual(confirm_response.status_code, 200)

        payment_response = self.client.post("/api/v1/payments/", {
            "booking": booking_id,
            "amount": 25000,
            "payment_method": "CASH",
            "payment_date": timezone.now().date().isoformat(),
        })
        self.assertEqual(payment_response.status_code, 201)

        invoice_response = self.client.post("/api/v1/invoices/generate/", {
            "booking_id": booking_id,
        })
        self.assertEqual(invoice_response.status_code, 201)

        progress_response = self.client.post(f"/api/v1/bookings/{booking_id}/mark_in_progress/")
        self.assertEqual(progress_response.status_code, 200)

        complete_response = self.client.post(f"/api/v1/bookings/{booking_id}/mark_completed/")
        self.assertEqual(complete_response.status_code, 200)

        booking = Booking.objects.get(id=booking_id)
        self.assertEqual(booking.status, "COMPLETED")
