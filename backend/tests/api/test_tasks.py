from django.utils import timezone
from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.tasks.models import Task
from apps.bookings.models import Booking
from apps.customers.models import Customer
from apps.venues.models import Venue


class TestTasksAPI(APITestCase):
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
            tenant=self.tenant, full_name="John Doe", mobile="8888888888",
        )
        self.venue = Venue.objects.create(
            tenant=self.tenant, name="Grand Hall",
            venue_type="BANQUET_HALL", capacity=200,
            weekday_price=50000, weekend_price=75000,
        )
        self.booking = Booking.objects.create(
            tenant=self.tenant, venue=self.venue, customer=self.customer,
            booking_number="VF-2026-000001", event_type="WEDDING",
            event_date=timezone.now().date() + timezone.timedelta(days=30),
            guest_count=100, total_amount=100000, status="CONFIRMED",
        )

    def test_create_task(self):
        response = self.client.post("/api/v1/tasks/", {
            "booking": self.booking.id,
            "title": "Arrange flowers",
            "priority": "HIGH",
        })
        self.assertEqual(response.status_code, 201)

    def test_list_tasks(self):
        Task.objects.create(tenant=self.tenant, booking=self.booking, title="Setup stage")
        response = self.client.get("/api/v1/tasks/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("results", response.data)

    def test_retrieve_task(self):
        task = Task.objects.create(tenant=self.tenant, booking=self.booking, title="Test task")
        response = self.client.get(f"/api/v1/tasks/{task.id}/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["title"], "Test task")

    def test_update_task(self):
        task = Task.objects.create(tenant=self.tenant, booking=self.booking, title="Old title")
        response = self.client.patch(f"/api/v1/tasks/{task.id}/", {"title": "Updated title"})
        self.assertEqual(response.status_code, 200)
        task.refresh_from_db()
        self.assertEqual(task.title, "Updated title")

    def test_change_task_status(self):
        task = Task.objects.create(tenant=self.tenant, booking=self.booking, title="Status test")
        response = self.client.post(f"/api/v1/tasks/{task.id}/status/", {"status": "IN_PROGRESS"})
        self.assertEqual(response.status_code, 200)
        task.refresh_from_db()
        self.assertEqual(task.status, "IN_PROGRESS")

    def test_tenant_isolation(self):
        other_tenant = Tenant.objects.create(
            business_name="Other", owner_name="Other",
            email="other@test.com", mobile="7777777777",
        )
        task = Task.objects.create(tenant=other_tenant, booking=self.booking, title="Secret task")
        response = self.client.get(f"/api/v1/tasks/{task.id}/")
        self.assertEqual(response.status_code, 404)
