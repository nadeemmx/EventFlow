import pytest
from django.utils import timezone
from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.customers.models import Customer
from apps.venues.models import Venue
from apps.leads.models import Lead, Quotation, QuotationItem


class TestQuotationsAPI(APITestCase):
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

    def test_create_quotation(self):
        response = self.client.post("/api/v1/quotations/", {
            "customer": self.customer.id,
            "valid_until": str(timezone.now().date() + timezone.timedelta(days=7)),
            "status": "DRAFT",
            "items": [
                {"item_name": "Venue Booking", "quantity": 1, "unit_price": 50000},
                {"item_name": "Catering", "quantity": 100, "unit_price": 500},
            ],
        })
        self.assertEqual(response.status_code, 201)
        self.assertTrue(response.data["success"])
        self.assertIn("items", response.data["data"])

    def test_list_quotations(self):
        q = Quotation.objects.create(
            tenant=self.tenant, customer=self.customer,
            subtotal=10000, total_amount=10000, status="DRAFT",
        )
        response = self.client.get("/api/v1/quotations/")
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["success"])

    def test_send_quotation(self):
        q = Quotation.objects.create(
            tenant=self.tenant, customer=self.customer,
            subtotal=10000, total_amount=10000, status="DRAFT",
        )
        response = self.client.post(f"/api/v1/quotations/{q.id}/send/")
        self.assertEqual(response.status_code, 200)
        q.refresh_from_db()
        self.assertEqual(q.status, "SENT")

    def test_reject_quotation(self):
        q = Quotation.objects.create(
            tenant=self.tenant, customer=self.customer,
            subtotal=10000, total_amount=10000, status="SENT",
        )
        response = self.client.post(f"/api/v1/quotations/{q.id}/reject/")
        self.assertEqual(response.status_code, 200)
        q.refresh_from_db()
        self.assertEqual(q.status, "REJECTED")
