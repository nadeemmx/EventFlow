from django.db import models
from core.base_models import BaseModel
from core.choices import TenantStatus
from core.validators import validate_image_file


class Tenant(BaseModel):
    business_name = models.CharField(max_length=255, db_index=True)
    owner_name = models.CharField(max_length=255, db_index=True)
    email = models.EmailField(unique=True, db_index=True)
    mobile = models.CharField(max_length=30, db_index=True)
    address = models.TextField(blank=True)
    gst_number = models.CharField(max_length=50, blank=True)
    logo = models.ImageField(upload_to="tenants/logos/", blank=True, validators=[validate_image_file])
    subscription_plan = models.ForeignKey(
        "subscriptions.SubscriptionPlan",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_index=True,
    )
    subscription_status = models.CharField(
        max_length=30, choices=TenantStatus.choices, default=TenantStatus.TRIAL, db_index=True
    )
    status = models.CharField(
        max_length=30, choices=TenantStatus.choices, default=TenantStatus.ACTIVE, db_index=True
    )

    class Meta:
        db_table = "tenants"
        verbose_name = "Tenant"
        verbose_name_plural = "Tenants"
        ordering = ["-created_at"]

    def __str__(self):
        return self.business_name


class TenantSettings(BaseModel):
    tenant = models.OneToOneField(Tenant, on_delete=models.CASCADE, related_name="settings", db_index=True)
    company_logo = models.ImageField(upload_to="tenants/settings/", blank=True, validators=[validate_image_file])
    company_name = models.CharField(max_length=255, blank=True)
    gst_details = models.TextField(blank=True)
    invoice_prefix = models.CharField(max_length=50, default="INV")
    currency = models.CharField(max_length=10, default="INR")
    timezone = models.CharField(max_length=50, default="Asia/Kolkata")
    gst_rate = models.DecimalField(max_digits=5, decimal_places=2, default=18.00)
    tentative_booking_validity_hours = models.IntegerField(default=48)

    class Meta:
        db_table = "tenant_settings"
        verbose_name = "Tenant Setting"
        verbose_name_plural = "Tenant Settings"

    def __str__(self):
        return f"Settings - {self.tenant.business_name}"
