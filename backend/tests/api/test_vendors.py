from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.vendors.models import Vendor


class TestVendorsAPI(APITestCase):
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

    def test_create_vendor(self):
        response = self.client.post("/api/v1/vendors/", {
            "name": "ABC Caterers",
            "vendor_type": "CATERER",
            "mobile": "9876543210",
        })
        self.assertEqual(response.status_code, 201)

    def test_list_vendors(self):
        Vendor.objects.create(tenant=self.tenant, name="Decorator Pro", vendor_type="DECORATOR", mobile="1111111111")
        response = self.client.get("/api/v1/vendors/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("results", response.data)

    def test_retrieve_vendor(self):
        vendor = Vendor.objects.create(tenant=self.tenant, name="Photo Studio", vendor_type="PHOTOGRAPHER", mobile="2222222222")
        response = self.client.get(f"/api/v1/vendors/{vendor.id}/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["name"], "Photo Studio")

    def test_update_vendor(self):
        vendor = Vendor.objects.create(tenant=self.tenant, name="Old Name", vendor_type="CATERER", mobile="3333333333")
        response = self.client.patch(f"/api/v1/vendors/{vendor.id}/", {"name": "New Name"})
        self.assertEqual(response.status_code, 200)
        vendor.refresh_from_db()
        self.assertEqual(vendor.name, "New Name")

    def test_tenant_isolation(self):
        other_tenant = Tenant.objects.create(
            business_name="Other", owner_name="Other",
            email="other@test.com", mobile="7777777777",
        )
        vendor = Vendor.objects.create(tenant=other_tenant, name="Other Vendor", vendor_type="OTHER", mobile="4444444444")
        response = self.client.get(f"/api/v1/vendors/{vendor.id}/")
        self.assertEqual(response.status_code, 404)
