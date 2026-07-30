from django.db import models
from core.base_models import TenantBaseModel
from core.choices import TaskPriority, TaskStatus


class Task(TenantBaseModel):
    booking = models.ForeignKey(
        "bookings.Booking", on_delete=models.CASCADE, related_name="tasks", db_index=True
    )
    assigned_to = models.ForeignKey(
        "staff.Staff", on_delete=models.SET_NULL, null=True, blank=True, db_index=True
    )
    title = models.CharField(max_length=255, db_index=True)
    description = models.TextField(blank=True)
    priority = models.CharField(
        max_length=30, choices=TaskPriority.choices, default=TaskPriority.MEDIUM, db_index=True
    )
    status = models.CharField(
        max_length=30, choices=TaskStatus.choices, default=TaskStatus.OPEN, db_index=True
    )
    due_date = models.DateTimeField(null=True, blank=True, db_index=True)

    class Meta:
        db_table = "tasks"
        verbose_name = "Task"
        verbose_name_plural = "Tasks"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["tenant", "status"]),
            models.Index(fields=["tenant", "assigned_to"]),
            models.Index(fields=["tenant", "created_at"]),
        ]

    def __str__(self):
        return self.title
