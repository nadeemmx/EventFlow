from django.db import models
from core.base_models import TenantBaseModel
from core.choices import StaffStatus


class Staff(TenantBaseModel):
    name = models.CharField(max_length=255, db_index=True)
    mobile = models.CharField(max_length=30, db_index=True)
    email = models.EmailField(max_length=255, blank=True, db_index=True)
    designation = models.CharField(max_length=255, blank=True, db_index=True)
    joining_date = models.DateField(null=True, blank=True, db_index=True)
    status = models.CharField(
        max_length=30, choices=StaffStatus.choices, default=StaffStatus.ACTIVE, db_index=True
    )

    class Meta:
        db_table = "staff"
        verbose_name = "Staff"
        verbose_name_plural = "Staff"
        ordering = ["-created_at"]
        unique_together = [("tenant", "mobile")]
        indexes = [
            models.Index(fields=["tenant", "status"]),
            models.Index(fields=["tenant", "created_at"]),
        ]

    def __str__(self):
        return self.name
