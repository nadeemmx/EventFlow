from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.venues.models import Venue


class TestVenuesAPI(APITestCase):
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

    def test_create_venue(self):
        response = self.client.post("/api/v1/venues/", {
            "name": "Grand Ballroom",
            "venue_type": "BANQUET_HALL",
            "capacity": 300,
            "weekday_price": 50000,
            "weekend_price": 75000,
        })
        self.assertEqual(response.status_code, 201)

    def test_list_venues(self):
        Venue.objects.create(
            tenant=self.tenant, name="Grand Hall",
            venue_type="BANQUET_HALL", capacity=200,
            weekday_price=50000, weekend_price=75000,
        )
        response = self.client.get("/api/v1/venues/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("results", response.data)

    def test_retrieve_venue(self):
        venue = Venue.objects.create(
            tenant=self.tenant, name="Grand Hall",
            venue_type="BANQUET_HALL", capacity=200,
            weekday_price=50000, weekend_price=75000,
        )
        response = self.client.get(f"/api/v1/venues/{venue.id}/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["name"], "Grand Hall")

    def test_update_venue(self):
        venue = Venue.objects.create(
            tenant=self.tenant, name="Grand Hall",
            venue_type="BANQUET_HALL", capacity=200,
            weekday_price=50000, weekend_price=75000,
        )
        response = self.client.patch(f"/api/v1/venues/{venue.id}/", {"capacity": 350})
        self.assertEqual(response.status_code, 200)
        venue.refresh_from_db()
        self.assertEqual(venue.capacity, 350)

    def test_tenant_isolation(self):
        other_tenant = Tenant.objects.create(
            business_name="Other", owner_name="Other",
            email="other@test.com", mobile="7777777777",
        )
        venue = Venue.objects.create(
            tenant=other_tenant, name="Other Hall",
            venue_type="BANQUET_HALL", capacity=100,
            weekday_price=25000, weekend_price=35000,
        )
        response = self.client.get(f"/api/v1/venues/{venue.id}/")
        self.assertEqual(response.status_code, 404)
