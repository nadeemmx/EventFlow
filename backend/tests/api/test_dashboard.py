from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User


class TestDashboardAPI(APITestCase):
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

    def test_dashboard_summary(self):
        response = self.client.get("/api/v1/dashboard/summary/")
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["success"])

    def test_dashboard_unauthenticated(self):
        self.client.force_authenticate(user=None)
        response = self.client.get("/api/v1/dashboard/summary/")
        self.assertEqual(response.status_code, 401)
