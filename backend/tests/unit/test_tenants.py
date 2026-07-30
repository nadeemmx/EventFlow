import pytest
from django.db import IntegrityError
from apps.tenants.models import Tenant, TenantSettings
from tests.factories import TenantFactory
from core.choices import TenantStatus


@pytest.mark.django_db
class TestTenantModel:
    def test_create_tenant(self):
        tenant = Tenant.objects.create(
            business_name="Test Venue Co",
            owner_name="Jane Owner",
            email="jane@venue.com",
            mobile="+911234567890",
        )
        assert tenant.business_name == "Test Venue Co"
        assert tenant.owner_name == "Jane Owner"
        assert tenant.email == "jane@venue.com"
        assert tenant.status == TenantStatus.ACTIVE
        assert tenant.subscription_status == TenantStatus.TRIAL

    def test_string_representation(self):
        tenant = TenantFactory(business_name="My Venue")
        assert str(tenant) == "My Venue"

    def test_email_unique_constraint(self):
        TenantFactory(email="unique@example.com")
        with pytest.raises(IntegrityError):
            TenantFactory(email="unique@example.com")

    def test_factory_sets_active_status(self):
        tenant = TenantFactory()
        assert tenant.status == TenantStatus.ACTIVE

    def test_factory_sets_active_subscription_status(self):
        tenant = TenantFactory()
        assert tenant.subscription_status == TenantStatus.ACTIVE


@pytest.mark.django_db
class TestTenantSettingsModel:
    def test_create_settings(self):
        tenant = TenantFactory()
        settings = TenantSettings.objects.create(
            tenant=tenant,
            company_name="My Venue Co",
            invoice_prefix="INV",
            currency="INR",
            gst_rate=18.00,
        )
        assert settings.tenant == tenant
        assert settings.company_name == "My Venue Co"
        assert settings.invoice_prefix == "INV"
        assert settings.currency == "INR"
        assert settings.gst_rate == 18.00

    def test_default_values(self):
        tenant = TenantFactory()
        settings = TenantSettings.objects.create(tenant=tenant)
        assert settings.invoice_prefix == "INV"
        assert settings.currency == "INR"
        assert settings.timezone == "Asia/Kolkata"
        assert settings.gst_rate == 18.00
        assert settings.tentative_booking_validity_hours == 48

    def test_one_to_one_relationship(self):
        tenant = TenantFactory()
        settings = TenantSettings.objects.create(tenant=tenant)
        assert tenant.settings == settings
        assert settings.tenant == tenant

    def test_string_representation(self):
        tenant = TenantFactory(business_name="ACME")
        settings = TenantSettings.objects.create(tenant=tenant)
        assert str(settings) == "Settings - ACME"

    def test_cascade_delete(self):
        tenant = TenantFactory()
        TenantSettings.objects.create(tenant=tenant)
        assert TenantSettings.objects.count() == 1
        tenant.delete()
        assert TenantSettings.objects.count() == 0
