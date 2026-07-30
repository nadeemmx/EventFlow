from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.packages.models import Package


class TestPackagesAPI(APITestCase):
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

    def test_create_package(self):
        response = self.client.post("/api/v1/packages/", {
            "name": "Silver Package",
            "base_price": 50000,
            "description": "Basic wedding package",
        })
        self.assertEqual(response.status_code, 201)

    def test_list_packages(self):
        Package.objects.create(tenant=self.tenant, name="Gold Package", base_price=100000)
        response = self.client.get("/api/v1/packages/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("results", response.data)

    def test_retrieve_package(self):
        package = Package.objects.create(tenant=self.tenant, name="Platinum", base_price=200000)
        response = self.client.get(f"/api/v1/packages/{package.id}/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["name"], "Platinum")

    def test_update_package(self):
        package = Package.objects.create(tenant=self.tenant, name="Basic", base_price=30000)
        response = self.client.patch(f"/api/v1/packages/{package.id}/", {"base_price": 35000})
        self.assertEqual(response.status_code, 200)
        package.refresh_from_db()
        self.assertEqual(package.base_price, 35000)

    def test_delete_package(self):
        package = Package.objects.create(tenant=self.tenant, name="Temp", base_price=10000)
        response = self.client.delete(f"/api/v1/packages/{package.id}/")
        self.assertEqual(response.status_code, 204)

    def test_tenant_isolation(self):
        other_tenant = Tenant.objects.create(
            business_name="Other", owner_name="Other",
            email="other@test.com", mobile="7777777777",
        )
        package = Package.objects.create(tenant=other_tenant, name="Secret", base_price=50000)
        response = self.client.get(f"/api/v1/packages/{package.id}/")
        self.assertEqual(response.status_code, 404)
