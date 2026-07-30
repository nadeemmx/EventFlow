from django.db import models
from core.base_models import TenantBaseModel
from core.choices import BookingStatus, EventType


class Booking(TenantBaseModel):
    booking_number = models.CharField(max_length=50, unique=True, db_index=True)
    venue = models.ForeignKey(
        "venues.Venue", on_delete=models.CASCADE, db_index=True, null=True, blank=True
    )
    customer = models.ForeignKey(
        "customers.Customer", on_delete=models.CASCADE, db_index=True
    )
    package = models.ForeignKey(
        "packages.Package", on_delete=models.SET_NULL, null=True, blank=True, db_index=True
    )
    event_type = models.CharField(
        max_length=50, choices=EventType.choices, db_index=True
    )
    event_date = models.DateField(db_index=True)
    guest_count = models.IntegerField()
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    advance_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    status = models.CharField(
        max_length=50, choices=BookingStatus.choices, default=BookingStatus.DRAFT, db_index=True
    )
    remarks = models.TextField(blank=True)

    class Meta:
        db_table = "bookings"
        verbose_name = "Booking"
        verbose_name_plural = "Bookings"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["tenant", "event_date"]),
            models.Index(fields=["tenant", "venue", "event_date"]),
            models.Index(fields=["tenant", "status"]),
            models.Index(fields=["tenant", "created_at"]),
        ]

    def __str__(self):
        return self.booking_number


class BookingHistory(TenantBaseModel):
    booking = models.ForeignKey(Booking, on_delete=models.CASCADE, related_name="history", db_index=True)
    old_status = models.CharField(max_length=50, blank=True)
    new_status = models.CharField(max_length=50)
    remarks = models.TextField(blank=True)

    class Meta:
        db_table = "booking_history"
        verbose_name = "Booking History"
        verbose_name_plural = "Booking Histories"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["tenant", "booking"]),
            models.Index(fields=["tenant", "created_at"]),
        ]

    def __str__(self):
        return f"{self.booking.booking_number}: {self.old_status} -> {self.new_status}"
