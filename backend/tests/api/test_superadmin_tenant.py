"""Regression tests for QA-TEST-REPORT-ROLES.md F-1 (P1).

SUPER_ADMIN is the platform role: ``users.tenant`` is nullable and
``ModuleAccessPermission`` short-circuits to allow every action
(``permissions/module_access.py``). But ``TenantBaseModel.tenant`` is NOT
NULL, and every viewset did ``serializer.save(tenant=request.tenant)`` with
``request.tenant is None`` — so *every* SUPER_ADMIN create raised
``NOT NULL constraint failed`` and surfaced as an HTTP 500 with a Django
debug page. The permission layer promised what the data layer refused.

The fix keeps the tenancy invariant intact (tenant stays NOT NULL) and
instead has SUPER_ADMIN name the tenant explicitly, resolved centrally in
``core/tenant_resolution.py`` and applied by ``TenantJWTAuthentication`` so
all 13 viewsets, every service, and the serializer FK-scoping inherit it.

These tests mint **real JWT access tokens** rather than using
``force_authenticate``: force-auth sets ``request._force_user`` and skips the
authenticators entirely, so it would bypass the very code under test.
"""
from django.test import TransactionTestCase
from rest_framework.test import APITestCase, APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.tenants.models import Tenant
from apps.users.models import User
from apps.customers.models import Customer
from apps.venues.models import Venue
from core.choices import UserRole, VenueType, VenueStatus


def _auth_as(client, user):
    """Point the client at a real Bearer token for ``user``."""
    access = str(RefreshToken.for_user(user).access_token)
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")


class SuperAdminTenantResolutionTests(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Alpha Events", owner_name="Owner",
            email="alpha@test.com", mobile="9999999999", status="ACTIVE",
        )
        self.superadmin = User.objects.create_superuser(
            email="root@test.com", password="rootpass123",
            full_name="Platform Root", tenant=None, role=UserRole.SUPER_ADMIN,
        )
        self.owner = User.objects.create_user(
            email="owner@test.com", password="ownerpass123",
            full_name="Tenant Owner", tenant=self.tenant, role=UserRole.OWNER,
        )
        _auth_as(self.client, self.superadmin)

    # --- create -----------------------------------------------------------

    def test_superadmin_creates_customer_with_explicit_tenant(self):
        response = self.client.post(
            "/api/v1/customers/",
            {"full_name": "Jane Doe", "mobile": "8888888888",
             "tenant": self.tenant.id},
            format="json",
        )
        self.assertEqual(response.status_code, 201, response.data)
        customer = Customer.objects.get(full_name="Jane Doe")
        self.assertEqual(customer.tenant_id, self.tenant.id)

    def test_superadmin_creates_venue_with_explicit_tenant(self):
        response = self.client.post(
            "/api/v1/venues/",
            {"name": "Grand Lawn", "venue_type": VenueType.MARRIAGE_LAWN,
             "capacity": 500, "status": VenueStatus.ACTIVE,
             "tenant": self.tenant.id},
            format="json",
        )
        self.assertEqual(response.status_code, 201, response.data)
        self.assertEqual(Venue.objects.get(name="Grand Lawn").tenant_id,
                         self.tenant.id)

    def test_superadmin_creates_booking_in_scoped_tenant(self):
        customer = Customer.objects.create(
            tenant=self.tenant, full_name="Walk-in", mobile="7777777777")
        venue = Venue.objects.create(
            tenant=self.tenant, name="Hall", venue_type=VenueType.BANQUET_HALL,
            capacity=200, status=VenueStatus.ACTIVE)
        response = self.client.post(
            "/api/v1/bookings/",
            {"venue": venue.id, "customer": customer.id,
             "event_type": "WEDDING", "event_date": "2027-01-15",
             "guest_count": 100, "total_amount": 50000,
             "tenant": self.tenant.id},
            format="json",
        )
        self.assertEqual(response.status_code, 201, response.data)

    # --- read path --------------------------------------------------------

    def test_superadmin_list_scoped_by_query_param(self):
        Customer.objects.create(
            tenant=self.tenant, full_name="Scoped", mobile="1111111111")
        response = self.client.get(f"/api/v1/customers/?tenant={self.tenant.id}")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 1)

    def test_superadmin_list_without_scope_is_empty_not_leaky(self):
        Customer.objects.create(
            tenant=self.tenant, full_name="Hidden", mobile="2222222222")
        response = self.client.get("/api/v1/customers/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 0)

    # --- no regression for ordinary tenants -------------------------------

    def test_tenant_owner_create_unaffected(self):
        _auth_as(self.client, self.owner)
        response = self.client.post(
            "/api/v1/customers/",
            {"full_name": "Owned", "mobile": "4444444444"},
            format="json",
        )
        self.assertEqual(response.status_code, 201, response.data)
        self.assertEqual(Customer.objects.get(full_name="Owned").tenant_id,
                         self.tenant.id)

    def test_tenant_owner_cannot_cross_tenants_via_payload(self):
        """An ordinary user must not be able to smuggle another tenant id."""
        other = Tenant.objects.create(
            business_name="Beta", owner_name="B", email="beta@test.com",
            mobile="8888111122", status="ACTIVE")
        _auth_as(self.client, self.owner)
        response = self.client.post(
            "/api/v1/customers/",
            {"full_name": "Smuggled", "mobile": "3333333333",
             "tenant": other.id},
            format="json",
        )
        self.assertEqual(response.status_code, 201, response.data)
        # payload tenant is ignored for non-SUPER_ADMIN: own tenant wins
        self.assertEqual(Customer.objects.get(full_name="Smuggled").tenant_id,
                         self.tenant.id)


class SuperAdminFailClosedTests(TransactionTestCase):
    """SUPER_ADMIN writes that cannot resolve a tenant must fail closed.

    These live in ``TransactionTestCase`` rather than ``TestCase`` on purpose:
    a rejected create trips the ``tenant`` NOT NULL constraint, and an
    ``IntegrityError`` marks the surrounding atomic block for rollback. Under
    ``TestCase``'s per-test atomic that would poison the connection and make
    the post-assertion queries raise ``TransactionManagementError`` instead of
    reporting the real behaviour. There is no ``ATOMIC_REQUESTS`` in
    production, so the response is returned cleanly before any of this.
    """

    def setUp(self):
        # TransactionTestCase hands out a plain Django Client; credentials()
        # and format="json" live on APIClient.
        self.client = APIClient()
        self.tenant = Tenant.objects.create(
            business_name="Alpha Events", owner_name="Owner",
            email="alpha@test.com", mobile="9999999999", status="ACTIVE")
        self.superadmin = User.objects.create_superuser(
            email="root@test.com", password="rootpass123",
            full_name="Platform Root", tenant=None, role=UserRole.SUPER_ADMIN)
        _auth_as(self.client, self.superadmin)

    def test_superadmin_create_without_tenant_is_rejected_not_500(self):
        """Before the fix this was a 500 with an HTML debug page."""
        response = self.client.post(
            "/api/v1/customers/",
            {"full_name": "No Tenant", "mobile": "6666666666"},
            format="json",
        )
        self.assertNotEqual(
            response.status_code, 500,
            f"must not 500, got {response.status_code}: {response.data}")
        self.assertEqual(
            response["Content-Type"].split(";")[0], "application/json")
        self.assertEqual(
            Customer.objects.filter(full_name="No Tenant").count(), 0)

    def test_superadmin_create_with_unknown_tenant_is_rejected_not_500(self):
        response = self.client.post(
            "/api/v1/customers/",
            {"full_name": "Ghost", "mobile": "5555555555", "tenant": 999999},
            format="json",
        )
        self.assertNotEqual(response.status_code, 500, response.data)
        self.assertEqual(Customer.objects.filter(full_name="Ghost").count(), 0)
