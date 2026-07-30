from django.utils import timezone
from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.contracts.models import Contract
from apps.bookings.models import Booking
from apps.customers.models import Customer
from apps.venues.models import Venue


class TestContractsAPI(APITestCase):
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

    def test_create_contract(self):
        response = self.client.post("/api/v1/contracts/", {
            "booking": self.booking.id,
            "content": "Contract terms and conditions",
        })
        self.assertEqual(response.status_code, 201)

    def test_list_contracts(self):
        Contract.objects.create(
            tenant=self.tenant, booking=self.booking,
            contract_number="CT-001", content="Terms",
        )
        response = self.client.get("/api/v1/contracts/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("pagination", response.data)

    def test_retrieve_contract(self):
        contract = Contract.objects.create(
            tenant=self.tenant, booking=self.booking,
            contract_number="CT-002", content="Sample",
        )
        response = self.client.get(f"/api/v1/contracts/{contract.id}/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("contract_number", response.data["data"])

    def test_sign_contract(self):
        contract = Contract.objects.create(
            tenant=self.tenant, booking=self.booking,
            contract_number="CT-003", content="Sign me",
            status="DRAFT",
        )
        response = self.client.post(f"/api/v1/contracts/{contract.id}/sign/", {
            "signed_by_name": "John Doe",
            "signed_by_designation": "Client",
        })
        self.assertEqual(response.status_code, 200)
        contract.refresh_from_db()
        self.assertEqual(contract.status, "SIGNED")

    def test_tenant_isolation(self):
        other_tenant = Tenant.objects.create(
            business_name="Other", owner_name="Other",
            email="other@test.com", mobile="7777777777",
        )
        contract = Contract.objects.create(
            tenant=other_tenant, booking=self.booking,
            contract_number="CT-SECRET", content="Secret",
        )
        response = self.client.get(f"/api/v1/contracts/{contract.id}/")
        self.assertEqual(response.status_code, 404)
