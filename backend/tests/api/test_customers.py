from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.customers.models import Customer


class TestCustomersAPI(APITestCase):
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

    def test_create_customer(self):
        response = self.client.post("/api/v1/customers/", {
            "full_name": "John Doe",
            "mobile": "8888888888",
            "email": "john@test.com",
        })
        self.assertEqual(response.status_code, 201)

    def test_list_customers(self):
        Customer.objects.create(
            tenant=self.tenant, full_name="John Doe",
            mobile="8888888888",
        )
        response = self.client.get("/api/v1/customers/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("results", response.data)

    def test_retrieve_customer(self):
        customer = Customer.objects.create(
            tenant=self.tenant, full_name="John Doe",
            mobile="8888888888",
        )
        response = self.client.get(f"/api/v1/customers/{customer.id}/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["full_name"], "John Doe")

    def test_update_customer(self):
        customer = Customer.objects.create(
            tenant=self.tenant, full_name="John Doe",
            mobile="8888888888",
        )
        response = self.client.patch(f"/api/v1/customers/{customer.id}/", {"full_name": "Jane Doe"})
        self.assertEqual(response.status_code, 200)
        customer.refresh_from_db()
        self.assertEqual(customer.full_name, "Jane Doe")

    def test_delete_customer(self):
        customer = Customer.objects.create(
            tenant=self.tenant, full_name="John Doe",
            mobile="8888888888",
        )
        response = self.client.delete(f"/api/v1/customers/{customer.id}/")
        self.assertEqual(response.status_code, 204)

    def test_tenant_isolation(self):
        other_tenant = Tenant.objects.create(
            business_name="Other", owner_name="Other",
            email="other@test.com", mobile="7777777777",
        )
        customer = Customer.objects.create(
            tenant=other_tenant, full_name="Other Guy",
            mobile="7777777777",
        )
        response = self.client.get(f"/api/v1/customers/{customer.id}/")
        self.assertEqual(response.status_code, 404)
