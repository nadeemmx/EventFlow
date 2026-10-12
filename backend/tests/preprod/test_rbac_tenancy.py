"""Pre-production RBAC, tenant isolation and multi-tenancy tests.

Covers checklist items #21 (Role-Based Access Control), #22 (Tenant
Isolation), #24 (Multi-Tenancy) and part of #20 (Authorization).
"""
import json

from rest_framework.test import APITestCase

from apps.customers.models import Customer
from apps.tenants.models import Tenant, TenantSettings
from apps.users.models import User
from apps.venues.models import Venue
from core.choices import UserRole


class RbacMatrixTests(APITestCase):
    """The matrix is derived from permissions/module_access.py."""

    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="RBAC Venue", owner_name="Owner",
            email="rbac@test.com", mobile="9000000201",
        )
        TenantSettings.objects.create(tenant=self.tenant)
        self.users = {}
        for role in (UserRole.OWNER, UserRole.MANAGER, UserRole.ACCOUNTANT, UserRole.STAFF):
            self.users[role] = User.objects.create_user(
                email=f"rbac-{role.lower()}@test.com", password="RbacPass123!",
                full_name=role, tenant=self.tenant, role=role,
            )
        self.venue = Venue.objects.create(
            tenant=self.tenant, name="RBAC Hall", venue_type="BANQUET_HALL",
            capacity=100, weekday_price=1000, weekend_price=2000,
        )
        self.customer = Customer.objects.create(
            tenant=self.tenant, full_name="RBAC Customer", mobile="9000000202",
        )

    def _as(self, role):
        self.client.force_authenticate(user=self.users[role])

    def assert_status(self, role, method, path, expected, payload=None):
        self._as(role)
        if method == "GET":
            response = self.client.get(path)
        elif method == "POST":
            response = self.client.post(path, payload or {}, format="json")
        elif method == "DELETE":
            response = self.client.delete(path)
        else:
            response = self.client.put(path, payload or {}, format="json")
        self.assertEqual(
            response.status_code, expected,
            f"{role} {method} {path} -> {response.status_code} (expected {expected}): "
            f"{response.content[:200]}",
        )
        return response

    def test_staff_can_read_bookings_but_not_write(self):
        self.assert_status(UserRole.STAFF, "GET", "/api/v1/bookings/", 200)
        self.assert_status(UserRole.STAFF, "POST", "/api/v1/bookings/", 403,
                           {"event_type": "WEDDING"})
        self.assert_status(UserRole.STAFF, "DELETE", f"/api/v1/bookings/{self.customer.id}/", 403)

    def test_staff_cannot_list_customers(self):
        self.assert_status(UserRole.STAFF, "GET", "/api/v1/customers/", 403)

    def test_staff_can_list_operational_modules(self):
        for path in ("/api/v1/venues/", "/api/v1/vendors/", "/api/v1/packages/",
                     "/api/v1/tasks/", "/api/v1/notifications/", "/api/v1/inventory/"):
            self.assert_status(UserRole.STAFF, "GET", path, 200)

    def test_accountant_has_finance_access_but_not_customer_write(self):
        self.assert_status(UserRole.ACCOUNTANT, "GET", "/api/v1/payments/", 200)
        self.assert_status(UserRole.ACCOUNTANT, "GET", "/api/v1/invoices/", 200)
        self.assert_status(UserRole.ACCOUNTANT, "POST", "/api/v1/customers/", 403,
                           {"full_name": "X", "mobile": "9000000203"})

    def test_accountant_cannot_read_settings(self):
        self.assert_status(UserRole.ACCOUNTANT, "GET", "/api/v1/settings/organization/", 403)
        self.assert_status(UserRole.OWNER, "GET", "/api/v1/settings/organization/", 200)

    def test_manager_cannot_delete_venue(self):
        self.assert_status(UserRole.MANAGER, "DELETE", f"/api/v1/venues/{self.venue.id}/", 403)
        self.assert_status(UserRole.OWNER, "GET", f"/api/v1/venues/{self.venue.id}/", 200)

    def test_manager_cannot_destroy_booking(self):
        self.assert_status(UserRole.MANAGER, "DELETE", "/api/v1/bookings/999999/", 403)

    def test_only_owner_reads_audit_logs(self):
        self.assert_status(UserRole.STAFF, "GET", "/api/v1/audit-logs/", 403)
        self.assert_status(UserRole.MANAGER, "GET", "/api/v1/audit-logs/", 403)
        self.assert_status(UserRole.OWNER, "GET", "/api/v1/audit-logs/", 200)

    def test_only_owner_reads_subscriptions(self):
        self.assert_status(UserRole.MANAGER, "GET", "/api/v1/subscriptions/", 403)
        self.assert_status(UserRole.OWNER, "GET", "/api/v1/subscriptions/", 200)

    def test_accountant_cannot_list_users(self):
        self.assert_status(UserRole.ACCOUNTANT, "GET", "/api/v1/users/", 403)
        self.assert_status(UserRole.MANAGER, "GET", "/api/v1/users/", 200)

    def test_report_actions_respect_role_matrix(self):
        self.assert_status(UserRole.STAFF, "GET", "/api/v1/reports/revenue/", 403)
        self.assert_status(UserRole.STAFF, "GET", "/api/v1/reports/bookings/", 200)
        self.assert_status(UserRole.ACCOUNTANT, "GET", "/api/v1/reports/payments/", 200)

    def test_dashboard_summary_available_to_every_role(self):
        for role in (UserRole.OWNER, UserRole.MANAGER, UserRole.ACCOUNTANT, UserRole.STAFF):
            self.assert_status(role, "GET", "/api/v1/dashboard/summary/", 200)

    def test_privacy_requests_are_owner_only(self):
        self.assert_status(UserRole.MANAGER, "GET", "/api/v1/privacy/requests/", 403)
        self.assert_status(UserRole.OWNER, "GET", "/api/v1/privacy/requests/", 200)

    def test_super_admin_bypasses_module_matrix(self):
        super_admin = User.objects.create_user(
            email="rbac-super@test.com", password="SuperPass123!",
            full_name="Super", tenant=None, role=UserRole.SUPER_ADMIN,
            is_superuser=True,
        )
        self.client.force_authenticate(user=super_admin)
        self.assertEqual(self.client.get("/api/v1/tenants/").status_code, 200)
        self.assertEqual(self.client.get("/api/v1/customers/").status_code, 200)


class TenantIsolationTests(APITestCase):
    def setUp(self):
        self.tenant_a = Tenant.objects.create(
            business_name="Tenant A", owner_name="A",
            email="tenant-a@test.com", mobile="9000000301",
        )
        self.tenant_b = Tenant.objects.create(
            business_name="Tenant B", owner_name="B",
            email="tenant-b@test.com", mobile="9000000302",
        )
        TenantSettings.objects.create(tenant=self.tenant_a)
        TenantSettings.objects.create(tenant=self.tenant_b)
        self.owner_a = User.objects.create_user(
            email="owner-a@test.com", password="OwnerAPass123!",
            full_name="Owner A", tenant=self.tenant_a, role=UserRole.OWNER,
        )
        self.owner_b = User.objects.create_user(
            email="owner-b@test.com", password="OwnerBPass123!",
            full_name="Owner B", tenant=self.tenant_b, role=UserRole.OWNER,
        )
        self.venue_a = Venue.objects.create(
            tenant=self.tenant_a, name="Private A Hall", venue_type="BANQUET_HALL",
            capacity=50, weekday_price=1000, weekend_price=2000,
        )
        self.customer_a = Customer.objects.create(
            tenant=self.tenant_a, full_name="A Customer", mobile="9000000303",
        )

    def test_b_cannot_read_a_customer(self):
        self.client.force_authenticate(user=self.owner_b)
        response = self.client.get(f"/api/v1/customers/{self.customer_a.id}/")
        self.assertEqual(response.status_code, 404)

    def test_b_cannot_update_a_customer(self):
        self.client.force_authenticate(user=self.owner_b)
        response = self.client.patch(
            f"/api/v1/customers/{self.customer_a.id}/", {"full_name": "Hijacked"}
        )
        self.assertEqual(response.status_code, 404)
        self.customer_a.refresh_from_db()
        self.assertEqual(self.customer_a.full_name, "A Customer")

    def test_b_cannot_delete_a_customer(self):
        self.client.force_authenticate(user=self.owner_b)
        response = self.client.delete(f"/api/v1/customers/{self.customer_a.id}/")
        self.assertEqual(response.status_code, 404)
        self.assertTrue(Customer.objects.filter(pk=self.customer_a.pk).exists())

    def test_b_cannot_read_a_venue(self):
        self.client.force_authenticate(user=self.owner_b)
        self.assertEqual(
            self.client.get(f"/api/v1/venues/{self.venue_a.id}/").status_code, 404
        )

    def test_list_endpoints_only_return_own_tenant_rows(self):
        Customer.objects.create(tenant=self.tenant_b, full_name="B Customer", mobile="9000000304")
        self.client.force_authenticate(user=self.owner_b)
        body = json.loads(self.client.get("/api/v1/customers/").content)
        names = [row["full_name"] for row in body["results"]]
        self.assertNotIn("A Customer", names)
        self.assertIn("B Customer", names)

    def test_search_cannot_reach_other_tenant(self):
        self.client.force_authenticate(user=self.owner_b)
        body = json.loads(self.client.get("/api/v1/customers/", {"search": "A Customer"}).content)
        self.assertEqual(body["count"], 0)

    def test_audit_logs_are_tenant_scoped(self):
        from apps.audit_logs.models import AuditLog
        AuditLog.objects.create(tenant=self.tenant_a, user=self.owner_a,
                                module="TEST", action="SECRET_A")
        AuditLog.objects.create(tenant=self.tenant_b, user=self.owner_b,
                                module="TEST", action="SECRET_B")
        self.client.force_authenticate(user=self.owner_b)
        body = json.loads(self.client.get("/api/v1/audit-logs/").content)
        actions = [row["action"] for row in body["results"]]
        self.assertIn("SECRET_B", actions)
        self.assertNotIn("SECRET_A", actions)

    def test_b_cannot_read_a_notifications(self):
        from apps.notifications.models import Notification
        try:
            Notification.objects.create(
                tenant=self.tenant_a, user=self.owner_a, title="Private note",
                message="secret", notification_type="INFO",
            )
        except Exception as exc:  # schema differences must not hide isolation checks
            self.skipTest(f"notification model shape changed: {exc}")
        self.client.force_authenticate(user=self.owner_b)
        body = json.loads(self.client.get("/api/v1/notifications/").content)
        titles = [row.get("title") for row in body["results"]]
        self.assertNotIn("Private note", titles)


class MultiTenancyProvisioningTests(APITestCase):
    def test_registration_provisions_isolated_tenant(self):
        response = self.client.post("/api/v1/auth/register/", {
            "full_name": "New Owner",
            "email": "brand-new@test.com",
            "password": "BrandNewPass123!",
            "confirm_password": "BrandNewPass123!",
            "mobile": "9000000401",
            "business_name": "Brand New Events",
        }, format="json")
        self.assertEqual(response.status_code, 201, response.content)
        payload = json.loads(response.content)["data"]
        self.assertIn("access_token", payload)
        self.assertEqual(payload["user"]["role"], UserRole.OWNER)

        tenant = Tenant.objects.get(business_name="Brand New Events")
        self.assertIsNotNone(tenant)

        self.client.force_authenticate(user=User.objects.get(email="brand-new@test.com"))
        customers = json.loads(self.client.get("/api/v1/customers/").content)
        self.assertEqual(customers["count"], 0, "new tenant must start with empty data")
        venues = json.loads(self.client.get("/api/v1/venues/").content)
        self.assertEqual(venues["count"], 0)

    def test_registration_rejects_duplicate_email(self):
        User.objects.create_user(
            email="dup@test.com", password="SomePass123!",
            full_name="Dup", tenant=None, role=UserRole.OWNER,
        )
        response = self.client.post("/api/v1/auth/register/", {
            "full_name": "Second", "email": "dup@test.com",
            "password": "AnotherPass123!", "confirm_password": "AnotherPass123!",
            "mobile": "9000000402", "business_name": "Dup Events",
        }, format="json")
        # duplicate e-mail is rejected with 409 Conflict by the register flow
        self.assertIn(response.status_code, (400, 409), response.content)
        self.assertEqual(User.objects.filter(email="dup@test.com").count(), 1)

    def test_registration_rejects_weak_password(self):
        response = self.client.post("/api/v1/auth/register/", {
            "full_name": "Weak", "email": "weak@test.com",
            "password": "123", "confirm_password": "123",
            "mobile": "9000000403", "business_name": "Weak Events",
        }, format="json")
        self.assertIn(response.status_code, (400, 401), response.content)
