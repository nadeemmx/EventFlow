from django.utils import timezone
from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.customers.models import Customer
from apps.venues.models import Venue
from apps.leads.models import Lead


class TestLeadFlow(APITestCase):
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
            tenant=self.tenant, full_name="Bob Wilson",
            mobile="8888888888",
        )
        self.venue = Venue.objects.create(
            tenant=self.tenant, name="Grand Hall",
            venue_type="BANQUET_HALL", capacity=200,
            weekday_price=50000, weekend_price=75000,
        )

    def test_lead_to_conversion(self):
        create_response = self.client.post("/api/v1/leads/", {
            "customer": self.customer.id,
            "lead_source": "WEBSITE",
            "notes": "Interested in wedding",
            "event_type": "WEDDING",
            "expected_event_date": str(timezone.now().date() + timezone.timedelta(days=30)),
            "expected_guest_count": 100,
        })
        self.assertEqual(create_response.status_code, 201)
        lead_id = create_response.data["id"]

        followup_response = self.client.post(f"/api/v1/leads/{lead_id}/add_followup/", {
            "followup_date": timezone.now().date().isoformat(),
            "notes": "Called customer, sent quotation",
        })
        self.assertEqual(followup_response.status_code, 201)

        update_response = self.client.patch(f"/api/v1/leads/{lead_id}/", {
            "lead_status": "QUOTATION_SENT",
        })
        self.assertEqual(update_response.status_code, 200)

        convert_response = self.client.post(f"/api/v1/leads/{lead_id}/convert/", {
            "venue_id": self.venue.id,
        })
        self.assertEqual(convert_response.status_code, 200)

        lead = Lead.objects.get(id=lead_id)
        self.assertEqual(lead.lead_status, "CONVERTED")
