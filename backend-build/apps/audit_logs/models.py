from django.db import models
from core.base_models import BaseModel


class AuditLog(BaseModel):
    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.CASCADE, null=True, blank=True, db_index=True
    )
    user = models.ForeignKey(
        "users.User", on_delete=models.SET_NULL, null=True, blank=True, db_index=True
    )
    module = models.CharField(max_length=255, db_index=True)
    action = models.CharField(max_length=255, db_index=True)
    record_id = models.BigIntegerField(null=True, blank=True, db_index=True)
    old_data = models.TextField(blank=True)
    new_data = models.TextField(blank=True)
    ip_address = models.CharField(max_length=255, blank=True)

    class Meta:
        db_table = "audit_logs"
        verbose_name = "Audit Log"
        verbose_name_plural = "Audit Logs"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["tenant", "created_at"]),
            models.Index(fields=["tenant", "module"]),
            models.Index(fields=["tenant", "action"]),
        ]

    def __str__(self):
        return f"{self.module} - {self.action}"
