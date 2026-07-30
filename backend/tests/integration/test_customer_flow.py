from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.customers.models import Customer


class TestCustomerFlow(APITestCase):
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

    def test_full_customer_lifecycle(self):
        create_response = self.client.post("/api/v1/customers/", {
            "full_name": "Alice Johnson",
            "mobile": "9999999999",
            "email": "alice@test.com",
        })
        self.assertEqual(create_response.status_code, 201)
        customer_id = create_response.data["id"]

        list_response = self.client.get("/api/v1/customers/")
        self.assertEqual(list_response.status_code, 200)
        self.assertIn("results", list_response.data)

        retrieve_response = self.client.get(f"/api/v1/customers/{customer_id}/")
        self.assertEqual(retrieve_response.status_code, 200)
        self.assertEqual(retrieve_response.data["full_name"], "Alice Johnson")

        update_response = self.client.patch(f"/api/v1/customers/{customer_id}/", {
            "full_name": "Alice Smith",
        })
        self.assertEqual(update_response.status_code, 200)
        customer = Customer.objects.get(id=customer_id)
        self.assertEqual(customer.full_name, "Alice Smith")

        delete_response = self.client.delete(f"/api/v1/customers/{customer_id}/")
        self.assertEqual(delete_response.status_code, 204)
