from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.staff.models import Staff


class TestStaffAPI(APITestCase):
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

    def test_create_staff(self):
        response = self.client.post("/api/v1/staff/", {
            "name": "John Worker",
            "mobile": "9988776655",
        })
        self.assertEqual(response.status_code, 201)

    def test_list_staff(self):
        Staff.objects.create(tenant=self.tenant, name="Alice", mobile="1111111111")
        response = self.client.get("/api/v1/staff/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("results", response.data)

    def test_retrieve_staff(self):
        staff = Staff.objects.create(tenant=self.tenant, name="Bob", mobile="2222222222")
        response = self.client.get(f"/api/v1/staff/{staff.id}/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["name"], "Bob")

    def test_update_staff(self):
        staff = Staff.objects.create(tenant=self.tenant, name="Charlie", mobile="3333333333")
        response = self.client.patch(f"/api/v1/staff/{staff.id}/", {"designation": "Manager"})
        self.assertEqual(response.status_code, 200)
        staff.refresh_from_db()
        self.assertEqual(staff.designation, "Manager")

    def test_tenant_isolation(self):
        other_tenant = Tenant.objects.create(
            business_name="Other", owner_name="Other",
            email="other@test.com", mobile="7777777777",
        )
        staff = Staff.objects.create(tenant=other_tenant, name="Intruder", mobile="4444444444")
        response = self.client.get(f"/api/v1/staff/{staff.id}/")
        self.assertEqual(response.status_code, 404)
