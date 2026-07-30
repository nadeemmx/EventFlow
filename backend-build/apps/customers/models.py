from django.db import models
from core.base_models import TenantBaseModel


class Customer(TenantBaseModel):
    full_name = models.CharField(max_length=255, db_index=True)
    mobile = models.CharField(max_length=30, db_index=True)
    email = models.EmailField(max_length=255, blank=True, db_index=True)
    address = models.TextField(blank=True)
    remarks = models.TextField(blank=True)

    class Meta:
        db_table = "customers"
        verbose_name = "Customer"
        verbose_name_plural = "Customers"
        ordering = ["-created_at"]
        unique_together = [("tenant", "mobile")]
        indexes = [
            models.Index(fields=["tenant", "created_at"]),
            models.Index(fields=["tenant", "full_name"]),
        ]

    def __str__(self):
        return f"{self.full_name} ({self.mobile})"
