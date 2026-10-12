from django.test import TestCase
from rest_framework.test import APIRequestFactory

from apps.bookings.serializers import BookingSerializer
from apps.customers.models import Customer
from apps.leads.serializers import LeadSerializer
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.venues.models import Venue
from core.choices import UserRole


class TenantScopedSerializerTests(TestCase):
    def setUp(self):
        self.factory = APIRequestFactory()
        self.tenant_a = Tenant.objects.create(
            business_name="Alpha Venue", owner_name="Owner",
            email="alpha@test.com", mobile="1111111111",
        )
        self.tenant_b = Tenant.objects.create(
            business_name="Beta Venue", owner_name="Owner B",
            email="beta@test.com", mobile="2222222222",
        )
        self.customer_a = Customer.objects.create(
            tenant=self.tenant_a, full_name="Customer A", mobile="8888888881",
        )
        self.customer_b = Customer.objects.create(
            tenant=self.tenant_b, full_name="Customer B", mobile="8888888882",
        )
        self.venue_a = Venue.objects.create(
            tenant=self.tenant_a, name="Hall A",
            venue_type="BANQUET_HALL", capacity=100,
            weekday_price=1000, weekend_price=2000,
        )

    def test_fields_scoped_to_request_tenant(self):
        request = self.factory.get("/")
        request.tenant = self.tenant_a
        serializer = BookingSerializer(context={"request": request})
        queryset = serializer.fields["customer"].queryset
        self.assertTrue(queryset.filter(id=self.customer_a.id).exists())
        self.assertFalse(queryset.filter(id=self.customer_b.id).exists())
        venue_queryset = serializer.fields["venue"].queryset
        self.assertTrue(venue_queryset.filter(id=self.venue_a.id).exists())

    def test_super_admin_without_tenant_keeps_unscoped_queryset(self):
        request = self.factory.get("/")
        request.tenant = None
        serializer = BookingSerializer(context={"request": request})
        queryset = serializer.fields["customer"].queryset
        self.assertTrue(queryset.filter(id=self.customer_a.id).exists())
        self.assertTrue(queryset.filter(id=self.customer_b.id).exists())

    def test_missing_context_leaves_queryset_untouched(self):
        serializer = BookingSerializer()
        queryset = serializer.fields["customer"].queryset
        self.assertTrue(queryset.filter(id=self.customer_b.id).exists())

    def test_lead_serializer_scopes_customer_and_assignee(self):
        request = self.factory.get("/")
        request.tenant = self.tenant_a
        owner = User.objects.create_user(
            email="owner@test.com", password="StrongPass123!",
            full_name="Owner", tenant=self.tenant_a, role=UserRole.OWNER,
        )
        outsider = User.objects.create_user(
            email="outsider@test.com", password="StrongPass123!",
            full_name="Outsider", tenant=self.tenant_b, role=UserRole.OWNER,
        )
        serializer = LeadSerializer(context={"request": request})
        customers = serializer.fields["customer"].queryset
        self.assertTrue(customers.filter(id=self.customer_a.id).exists())
        self.assertFalse(customers.filter(id=self.customer_b.id).exists())
        assignees = serializer.fields["assigned_to"].queryset
        self.assertTrue(assignees.filter(id=owner.id).exists())
        self.assertFalse(assignees.filter(id=outsider.id).exists())
