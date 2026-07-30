import pytest
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework import status
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.customers.models import Customer
from apps.venues.models import Venue
from apps.bookings.models import Booking
from apps.contracts.models import Contract


class TestContractsAPI(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Test Venue",
            owner_name="Owner",
            email="test@test.com",
            mobile="9999999999",
        )
        self.user = User.objects.create_user(
            email="admin@test.com",
            password="testpass123",
            full_name="Admin",
            tenant=self.tenant,
            role="OWNER",
        )
        self.client.force_authenticate(user=self.user)
        self.customer = Customer.objects.create(
            tenant=self.tenant, full_name="John Doe",
            mobile="8888888888", email="john@test.com",
        )
        self.venue = Venue.objects.create(
            tenant=self.tenant, name="Grand Hall",
            venue_type="BANQUET_HALL", capacity=200,
            weekday_price=50000, weekend_price=75000,
        )
        self.booking = Booking.objects.create(
            tenant=self.tenant,
            booking_number="VF-2026-000001",
            venue=self.venue,
            customer=self.customer,
            event_type="WEDDING",
            event_date=timezone.now().date(),
            guest_count=100,
            total_amount=100000,
            advance_amount=25000,
            status="CONFIRMED",
        )

    def test_generate_contract(self):
        response = self.client.post("/api/v1/contracts/generate/", {
            "booking_id": self.booking.id,
            "valid_from": str(timezone.now().date()),
            "valid_until": str(timezone.now().date() + timezone.timedelta(days=30)),
            "notes": "Test contract",
        })
        self.assertEqual(response.status_code, 201)
        self.assertTrue(response.data["success"])
        self.assertIn("contract_number", response.data["data"])

    def test_list_contracts(self):
        Contract.objects.create(
            tenant=self.tenant, booking=self.booking,
            contract_number="CTR-2026-000001",
            status="DRAFT",
        )
        response = self.client.get("/api/v1/contracts/")
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["success"])
        self.assertEqual(len(response.data["data"]), 1)

    def test_retrieve_contract(self):
        contract = Contract.objects.create(
            tenant=self.tenant, booking=self.booking,
            contract_number="CTR-2026-000001",
            status="DRAFT",
        )
        response = self.client.get(f"/api/v1/contracts/{contract.id}/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["data"]["contract_number"], "CTR-2026-000001")

    def test_sign_contract(self):
        contract = Contract.objects.create(
            tenant=self.tenant, booking=self.booking,
            contract_number="CTR-2026-000001",
            status="DRAFT",
        )
        response = self.client.post(f"/api/v1/contracts/{contract.id}/sign/", {
            "signed_by_name": "John Doe",
            "signed_by_designation": "Client",
        })
        self.assertEqual(response.status_code, 200)
        contract.refresh_from_db()
        self.assertEqual(contract.status, "SIGNED")

    def test_cancel_contract(self):
        contract = Contract.objects.create(
            tenant=self.tenant, booking=self.booking,
            contract_number="CTR-2026-000001",
            status="DRAFT",
        )
        response = self.client.post(f"/api/v1/contracts/{contract.id}/cancel/")
        self.assertEqual(response.status_code, 200)
        contract.refresh_from_db()
        self.assertEqual(contract.status, "CANCELLED")

    def test_tenant_isolation(self):
        other_tenant = Tenant.objects.create(
            business_name="Other", owner_name="Other",
            email="other@test.com", mobile="7777777777",
        )
        contract = Contract.objects.create(
            tenant=other_tenant, booking=self.booking,
            contract_number="CTR-2026-999999",
            status="DRAFT",
        )
        response = self.client.get(f"/api/v1/contracts/{contract.id}/")
        self.assertEqual(response.status_code, 404)


class TestBookingEnhancedFlow(APITestCase):
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
            booking_number="VF-2026-000002",
            venue=self.venue, customer=self.customer,
            event_type="WEDDING",
            event_date=timezone.now().date(),
            guest_count=100, total_amount=100000,
            advance_amount=50000, status="CONFIRMED",
        )

    def test_mark_in_progress(self):
        response = self.client.post(f"/api/v1/bookings/{self.booking.id}/mark_in_progress/")
        self.assertEqual(response.status_code, 200)
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, "IN_PROGRESS")

    def test_mark_completed(self):
        self.booking.status = "IN_PROGRESS"
        self.booking.save()
        response = self.client.post(f"/api/v1/bookings/{self.booking.id}/mark_completed/")
        self.assertEqual(response.status_code, 200)
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, "COMPLETED")


class TestReportsAPI(APITestCase):
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

    def test_revenue_report(self):
        response = self.client.get("/api/v1/reports/revenue/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("total_revenue", response.data["data"])

    def test_booking_report(self):
        response = self.client.get("/api/v1/reports/bookings/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("total_bookings", response.data["data"])

    def test_lead_report(self):
        response = self.client.get("/api/v1/reports/leads/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("total_leads", response.data["data"])

    def test_outstanding_payments_report(self):
        response = self.client.get("/api/v1/reports/outstanding/")
        self.assertEqual(response.status_code, 200)
        self.assertIsInstance(response.data["data"], list)

    def test_monthly_growth_report(self):
        response = self.client.get("/api/v1/reports/monthly_growth/")
        self.assertEqual(response.status_code, 200)
        self.assertIsInstance(response.data["data"], list)

    def test_vendor_report(self):
        response = self.client.get("/api/v1/reports/vendors/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("total_vendors", response.data["data"])

    def test_inventory_report(self):
        response = self.client.get("/api/v1/reports/inventory/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("total_items", response.data["data"])
