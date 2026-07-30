from django.db import models
from core.base_models import TenantBaseModel
from core.choices import LeadStatus, LeadSource, EventType, QuotationStatus


class Lead(TenantBaseModel):
    customer = models.ForeignKey(
        "customers.Customer", on_delete=models.CASCADE, related_name="leads", db_index=True
    )
    lead_source = models.CharField(
        max_length=50, choices=LeadSource.choices, default=LeadSource.WALK_IN, db_index=True
    )
    event_type = models.CharField(
        max_length=50, choices=EventType.choices, blank=True, db_index=True
    )
    expected_event_date = models.DateField(null=True, blank=True, db_index=True)
    expected_guest_count = models.IntegerField(null=True, blank=True)
    lead_status = models.CharField(
        max_length=50, choices=LeadStatus.choices, default=LeadStatus.NEW, db_index=True
    )
    assigned_to = models.ForeignKey(
        "users.User", on_delete=models.SET_NULL, null=True, blank=True, db_index=True
    )

    class Meta:
        db_table = "leads"
        verbose_name = "Lead"
        verbose_name_plural = "Leads"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["tenant", "lead_status"]),
            models.Index(fields=["tenant", "created_at"]),
            models.Index(fields=["tenant", "lead_source"]),
        ]

    def __str__(self):
        return f"Lead - {self.customer.full_name}"


class FollowUp(TenantBaseModel):
    lead = models.ForeignKey(Lead, on_delete=models.CASCADE, related_name="followups", db_index=True)
    followup_date = models.DateField(db_index=True)
    notes = models.TextField(blank=True)
    next_action = models.TextField(blank=True)

    class Meta:
        db_table = "followups"
        verbose_name = "Follow Up"
        verbose_name_plural = "Follow Ups"
        ordering = ["-followup_date"]
        indexes = [
            models.Index(fields=["tenant", "followup_date"]),
            models.Index(fields=["tenant", "lead"]),
        ]

    def __str__(self):
        return f"FollowUp - {self.lead.customer.full_name}"


class Quotation(TenantBaseModel):
    lead = models.ForeignKey(Lead, on_delete=models.CASCADE, related_name="quotations", null=True, blank=True, db_index=True)
    customer = models.ForeignKey("customers.Customer", on_delete=models.CASCADE, db_index=True)
    venue = models.ForeignKey("venues.Venue", on_delete=models.SET_NULL, null=True, blank=True, db_index=True)
    package = models.ForeignKey("packages.Package", on_delete=models.SET_NULL, null=True, blank=True, db_index=True)
    valid_until = models.DateField(null=True, blank=True, db_index=True)
    status = models.CharField(
        max_length=30, choices=QuotationStatus.choices, default=QuotationStatus.DRAFT, db_index=True
    )
    subtotal = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    tax_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    class Meta:
        db_table = "quotations"
        verbose_name = "Quotation"
        verbose_name_plural = "Quotations"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["tenant", "status"]),
            models.Index(fields=["tenant", "created_at"]),
        ]

    def __str__(self):
        return f"Quotation - {self.customer.full_name}"


class QuotationItem(TenantBaseModel):
    quotation = models.ForeignKey(Quotation, on_delete=models.CASCADE, related_name="items", db_index=True)
    item_name = models.CharField(max_length=255)
    quantity = models.IntegerField(default=1)
    unit_price = models.DecimalField(max_digits=12, decimal_places=2)
    total_price = models.DecimalField(max_digits=12, decimal_places=2)

    class Meta:
        db_table = "quotation_items"

    def __str__(self):
        return f"{self.item_name} x {self.quantity}"
