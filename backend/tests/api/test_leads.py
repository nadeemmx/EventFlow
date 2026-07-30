from django.utils import timezone
from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.customers.models import Customer
from apps.venues.models import Venue
from apps.leads.models import Lead


class TestLeadsAPI(APITestCase):
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

    def test_create_lead(self):
        response = self.client.post("/api/v1/leads/", {
            "customer": self.customer.id,
            "lead_source": "WEBSITE",
            "notes": "Interested in wedding",
        })
        self.assertEqual(response.status_code, 201)

    def test_list_leads(self):
        Lead.objects.create(
            tenant=self.tenant, customer=self.customer,
            lead_status="NEW", lead_source="WEBSITE",
        )
        response = self.client.get("/api/v1/leads/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("results", response.data)

    def test_retrieve_lead(self):
        lead = Lead.objects.create(
            tenant=self.tenant, customer=self.customer,
            lead_status="NEW", lead_source="WEBSITE",
        )
        response = self.client.get(f"/api/v1/leads/{lead.id}/")
        self.assertEqual(response.status_code, 200)

    def test_update_lead(self):
        lead = Lead.objects.create(
            tenant=self.tenant, customer=self.customer,
            lead_status="NEW", lead_source="WEBSITE",
        )
        response = self.client.patch(f"/api/v1/leads/{lead.id}/", {"lead_status": "CONTACTED"})
        self.assertEqual(response.status_code, 200)
        lead.refresh_from_db()
        self.assertEqual(lead.lead_status, "CONTACTED")

    def test_convert_lead(self):
        lead = Lead.objects.create(
            tenant=self.tenant, customer=self.customer,
            lead_status="QUOTATION_SENT", lead_source="WEBSITE",
            event_type="WEDDING",
            expected_event_date=timezone.now().date() + timezone.timedelta(days=30),
            expected_guest_count=100,
        )
        response = self.client.post(f"/api/v1/leads/{lead.id}/convert/", {
            "venue_id": self.venue.id,
        })
        self.assertEqual(response.status_code, 200)
        lead.refresh_from_db()
        self.assertEqual(lead.lead_status, "CONVERTED")

    def test_add_followup(self):
        lead = Lead.objects.create(
            tenant=self.tenant, customer=self.customer,
            lead_status="NEW", lead_source="WEBSITE",
        )
        response = self.client.post(f"/api/v1/leads/{lead.id}/add_followup/", {
            "followup_date": timezone.now().date().isoformat(),
            "notes": "Called customer",
        })
        self.assertEqual(response.status_code, 201)

    def test_tenant_isolation(self):
        other_tenant = Tenant.objects.create(
            business_name="Other", owner_name="Other",
            email="other@test.com", mobile="7777777777",
        )
        lead = Lead.objects.create(
            tenant=other_tenant, customer=self.customer,
            lead_status="NEW", lead_source="WEBSITE",
        )
        response = self.client.get(f"/api/v1/leads/{lead.id}/")
        self.assertEqual(response.status_code, 404)
