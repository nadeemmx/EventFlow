from django.db import models
from core.base_models import BaseModel
from core.choices import (
    SubscriptionPlanName, BillingCycle, SubscriptionStatus,
)

class SubscriptionPlan(BaseModel):
    plan_name = models.CharField(
        max_length=255, choices=SubscriptionPlanName.choices, db_index=True
    )
    monthly_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    yearly_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    max_users = models.IntegerField(default=3)
    max_venues = models.IntegerField(default=1)
    max_bookings_per_month = models.IntegerField(default=100)
    storage_limit_mb = models.IntegerField(default=2048)
    features = models.JSONField(default=dict, blank=True)
    status = models.CharField(max_length=30, default="ACTIVE", db_index=True)

    class Meta:
        db_table = "subscription_plans"
        verbose_name = "Subscription Plan"
        verbose_name_plural = "Subscription Plans"
        ordering = ["-created_at"]

    def __str__(self):
        return self.get_plan_name_display()


class Subscription(BaseModel):
    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.CASCADE, related_name="subscriptions", db_index=True
    )
    plan = models.ForeignKey(SubscriptionPlan, on_delete=models.SET_NULL, null=True, db_index=True)
    start_date = models.DateField(db_index=True)
    end_date = models.DateField(db_index=True)
    billing_cycle = models.CharField(
        max_length=30, choices=BillingCycle.choices, default=BillingCycle.MONTHLY, db_index=True
    )
    status = models.CharField(
        max_length=30, choices=SubscriptionStatus.choices, default=SubscriptionStatus.TRIAL, db_index=True
    )

    class Meta:
        db_table = "subscriptions"
        verbose_name = "Subscription"
        verbose_name_plural = "Subscriptions"
        ordering = ["-start_date"]
        indexes = [
            models.Index(fields=["tenant", "status"]),
            models.Index(fields=["tenant", "start_date"]),
        ]

    def __str__(self):
        return f"{self.tenant.business_name} - {self.get_status_display()}"


class CreditBalance(BaseModel):
    tenant = models.ForeignKey("tenants.Tenant", on_delete=models.CASCADE, related_name="credit_balances", db_index=True)
    credit_type = models.CharField(max_length=50, db_index=True)
    balance = models.IntegerField(default=0)

    class Meta:
        db_table = "credit_balances"
        ordering = ["-created_at"]
        unique_together = [("tenant", "credit_type")]
        indexes = [
            models.Index(fields=["tenant", "credit_type"]),
        ]


class CreditTransaction(BaseModel):
    tenant = models.ForeignKey("tenants.Tenant", on_delete=models.CASCADE, db_index=True)
    credit_balance = models.ForeignKey(CreditBalance, on_delete=models.CASCADE, db_index=True)
    quantity = models.IntegerField()
    transaction_type = models.CharField(max_length=30, db_index=True)
    description = models.TextField(blank=True)

    class Meta:
        db_table = "credit_transactions"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["tenant", "transaction_type"]),
            models.Index(fields=["tenant", "created_at"]),
        ]
