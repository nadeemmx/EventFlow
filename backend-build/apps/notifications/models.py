from django.db import models
from core.base_models import BaseModel
from core.choices import NotificationChannel, NotificationStatus


class Notification(BaseModel):
    tenant = models.ForeignKey(
        "tenants.Tenant", on_delete=models.CASCADE, null=True, blank=True, db_index=True
    )
    user = models.ForeignKey(
        "users.User", on_delete=models.CASCADE, null=True, blank=True, db_index=True
    )
    title = models.CharField(max_length=255, db_index=True)
    message = models.TextField()
    channel = models.CharField(
        max_length=30, choices=NotificationChannel.choices, default=NotificationChannel.IN_APP, db_index=True
    )
    status = models.CharField(
        max_length=30, choices=NotificationStatus.choices, default=NotificationStatus.PENDING, db_index=True
    )

    class Meta:
        db_table = "notifications"
        verbose_name = "Notification"
        verbose_name_plural = "Notifications"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["tenant", "user", "created_at"]),
            models.Index(fields=["tenant", "status"]),
        ]

    def __str__(self):
        return self.title
