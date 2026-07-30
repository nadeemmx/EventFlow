from django.utils import timezone
from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.leads.models import Lead, Quotation, FollowUp, QuotationItem
from apps.customers.models import Customer
from apps.venues.models import Venue


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
            tenant=self.tenant, full_name="John Doe", mobile="8888888888",
        )
        self.venue = Venue.objects.create(
            tenant=self.tenant, name="Grand Hall",
            venue_type="BANQUET_HALL", capacity=200,
            weekday_price=50000, weekend_price=75000,
        )
        self.lead = Lead.objects.create(
            tenant=self.tenant, customer=self.customer,
            lead_source="WALK_IN", lead_status="NEW",
            expected_event_date=timezone.now().date() + timezone.timedelta(days=60),
            expected_guest_count=150,
        )

    def test_create_quotation(self):
        response = self.client.post("/api/v1/quotations/", {
            "lead": self.lead.id,
            "customer": self.customer.id,
            "venue": self.venue.id,
            "valid_until": str(timezone.now().date() + timezone.timedelta(days=7)),
            "subtotal": 100000,
            "tax_amount": 18000,
            "total_amount": 118000,
        })
        self.assertEqual(response.status_code, 201)

    def test_list_quotations(self):
        Quotation.objects.create(
            tenant=self.tenant, lead=self.lead, customer=self.customer,
            total_amount=50000,
        )
        response = self.client.get("/api/v1/quotations/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("pagination", response.data)

    def test_accept_quotation(self):
        quotation = Quotation.objects.create(
            tenant=self.tenant, lead=self.lead, customer=self.customer,
            venue=self.venue, total_amount=100000, status="DRAFT",
        )
        response = self.client.post(f"/api/v1/quotations/{quotation.id}/accept/")
        self.assertEqual(response.status_code, 200)
        quotation.refresh_from_db()
        self.assertEqual(quotation.status, "ACCEPTED")

    def test_reject_quotation(self):
        quotation = Quotation.objects.create(
            tenant=self.tenant, lead=self.lead, customer=self.customer,
            total_amount=75000, status="SENT",
        )
        response = self.client.post(f"/api/v1/quotations/{quotation.id}/reject/")
        self.assertEqual(response.status_code, 200)
        quotation.refresh_from_db()
        self.assertEqual(quotation.status, "REJECTED")

    def test_send_quotation(self):
        quotation = Quotation.objects.create(
            tenant=self.tenant, lead=self.lead, customer=self.customer,
            total_amount=80000, status="DRAFT",
        )
        response = self.client.post(f"/api/v1/quotations/{quotation.id}/send/")
        self.assertEqual(response.status_code, 200)
        quotation.refresh_from_db()
        self.assertEqual(quotation.status, "SENT")

    def test_tenant_isolation(self):
        other_tenant = Tenant.objects.create(
            business_name="Other", owner_name="Other",
            email="other@test.com", mobile="7777777777",
        )
        quotation = Quotation.objects.create(
            tenant=other_tenant, lead=self.lead, customer=self.customer,
            total_amount=99999,
        )
        response = self.client.get(f"/api/v1/quotations/{quotation.id}/")
        self.assertEqual(response.status_code, 404)
