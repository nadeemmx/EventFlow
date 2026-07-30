from django.db import models
from core.base_models import TenantBaseModel
from core.choices import PaymentMethod, PaymentType


class Payment(TenantBaseModel):
    booking = models.ForeignKey(
        "bookings.Booking", on_delete=models.CASCADE, related_name="payments", db_index=True
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    payment_method = models.CharField(
        max_length=50, choices=PaymentMethod.choices, default=PaymentMethod.CASH, db_index=True
    )
    payment_type = models.CharField(
        max_length=30, choices=PaymentType.choices, default=PaymentType.PAYMENT, db_index=True
    )
    transaction_reference = models.CharField(max_length=255, blank=True)
    payment_date = models.DateField(db_index=True)
    notes = models.TextField(blank=True)

    class Meta:
        db_table = "payments"
        verbose_name = "Payment"
        verbose_name_plural = "Payments"
        ordering = ["-payment_date"]
        indexes = [
            models.Index(fields=["booking", "payment_type"]),
            models.Index(fields=["tenant", "payment_date"]),
            models.Index(fields=["tenant", "created_at"]),
        ]

    def __str__(self):
        return f"Payment - {self.booking.booking_number} ({self.amount})"
