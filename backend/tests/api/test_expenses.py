from django.utils import timezone
from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.expenses.models import Expense


class TestExpensesAPI(APITestCase):
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

    def test_create_expense(self):
        response = self.client.post("/api/v1/expenses/", {
            "expense_category": "UTILITIES",
            "amount": 15000,
            "expense_date": str(timezone.now().date()),
        })
        self.assertEqual(response.status_code, 201)

    def test_list_expenses(self):
        Expense.objects.create(
            tenant=self.tenant, expense_category="MAINTENANCE",
            amount=5000, expense_date=timezone.now().date(),
        )
        response = self.client.get("/api/v1/expenses/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("results", response.data)

    def test_retrieve_expense(self):
        expense = Expense.objects.create(
            tenant=self.tenant, expense_category="FOOD",
            amount=25000, expense_date=timezone.now().date(),
        )
        response = self.client.get(f"/api/v1/expenses/{expense.id}/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["expense_category"], "FOOD")

    def test_update_expense(self):
        expense = Expense.objects.create(
            tenant=self.tenant, expense_category="DECOR",
            amount=10000, expense_date=timezone.now().date(),
        )
        response = self.client.patch(f"/api/v1/expenses/{expense.id}/", {"amount": 12000})
        self.assertEqual(response.status_code, 200)
        expense.refresh_from_db()
        self.assertEqual(expense.amount, 12000)

    def test_tenant_isolation(self):
        other_tenant = Tenant.objects.create(
            business_name="Other", owner_name="Other",
            email="other@test.com", mobile="7777777777",
        )
        expense = Expense.objects.create(
            tenant=other_tenant, expense_category="OTHER",
            amount=9999, expense_date=timezone.now().date(),
        )
        response = self.client.get(f"/api/v1/expenses/{expense.id}/")
        self.assertEqual(response.status_code, 404)
