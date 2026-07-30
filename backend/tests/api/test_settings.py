from rest_framework.test import APITestCase
from apps.tenants.models import Tenant, TenantSettings
from apps.users.models import User


class TestSettingsAPI(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Test Venue", owner_name="Owner",
            email="test@test.com", mobile="9999999999",
        )
        TenantSettings.objects.create(tenant=self.tenant)
        self.user = User.objects.create_user(
            email="admin@test.com", password="testpass123",
            full_name="Admin", tenant=self.tenant, role="OWNER",
        )
        self.client.force_authenticate(user=self.user)

    def test_organization_settings(self):
        response = self.client.get("/api/v1/settings/organization/")
        self.assertEqual(response.status_code, 200)

    def test_profile_settings(self):
        response = self.client.get("/api/v1/settings/profile/")
        self.assertEqual(response.status_code, 200)

    def test_branding_settings(self):
        response = self.client.get("/api/v1/settings/branding/")
        self.assertEqual(response.status_code, 200)
