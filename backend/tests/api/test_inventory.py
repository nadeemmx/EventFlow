from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.inventory.models import InventoryItem
from apps.bookings.models import Booking
from apps.customers.models import Customer
from apps.venues.models import Venue
from django.utils import timezone


class TestInventoryAPI(APITestCase):
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

    def test_create_inventory_item(self):
        response = self.client.post("/api/v1/inventory/", {
            "item_name": "Gold Chair",
            "category": "CHAIRS",
            "total_quantity": 100,
        })
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["available_quantity"], 100)

    def test_list_inventory(self):
        InventoryItem.objects.create(tenant=self.tenant, item_name="Tables", category="TABLES", total_quantity=50)
        response = self.client.get("/api/v1/inventory/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("results", response.data)

    def test_retrieve_inventory(self):
        item = InventoryItem.objects.create(tenant=self.tenant, item_name="Chair", category="CHAIRS", total_quantity=200)
        response = self.client.get(f"/api/v1/inventory/{item.id}/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["item_name"], "Chair")

    def test_update_inventory(self):
        item = InventoryItem.objects.create(tenant=self.tenant, item_name="Table", category="TABLES", total_quantity=30)
        response = self.client.patch(f"/api/v1/inventory/{item.id}/", {"total_quantity": 50})
        self.assertEqual(response.status_code, 200)
        item.refresh_from_db()
        self.assertEqual(item.total_quantity, 50)

    def test_allocate_inventory(self):
        item = InventoryItem.objects.create(
            tenant=self.tenant, item_name="Chair", category="CHAIRS",
            total_quantity=100, available_quantity=100,
        )
        booking = Booking.objects.create(
            tenant=self.tenant, venue=self.venue, customer=self.customer,
            booking_number="VF-2026-000001", event_type="WEDDING",
            event_date=timezone.now().date() + timezone.timedelta(days=30),
            guest_count=100, total_amount=100000, status="CONFIRMED",
        )
        response = self.client.post("/api/v1/inventory/allocate/", {
            "booking_id": booking.id,
            "inventory_item_id": item.id,
            "quantity": 10,
        })
        self.assertEqual(response.status_code, 200)

    def test_release_inventory(self):
        item = InventoryItem.objects.create(
            tenant=self.tenant, item_name="Chair", category="CHAIRS",
            total_quantity=100, available_quantity=90,
        )
        booking = Booking.objects.create(
            tenant=self.tenant, venue=self.venue, customer=self.customer,
            booking_number="VF-2026-000002", event_type="WEDDING",
            event_date=timezone.now().date() + timezone.timedelta(days=30),
            guest_count=100, total_amount=100000, status="CONFIRMED",
        )
        self.client.post("/api/v1/inventory/allocate/", {
            "booking_id": booking.id,
            "inventory_item_id": item.id,
            "quantity": 10,
        })
        response = self.client.post("/api/v1/inventory/release/", {
            "booking_id": booking.id,
        })
        self.assertEqual(response.status_code, 200)
