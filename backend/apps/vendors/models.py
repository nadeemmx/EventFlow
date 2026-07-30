from django.db import models
from core.base_models import TenantBaseModel
from core.choices import VendorType, VendorStatus


class Vendor(TenantBaseModel):
    name = models.CharField(max_length=255, db_index=True)
    vendor_type = models.CharField(
        max_length=100, choices=VendorType.choices, default=VendorType.OTHER, db_index=True
    )
    mobile = models.CharField(max_length=30, db_index=True)
    email = models.EmailField(max_length=255, blank=True, db_index=True)
    address = models.TextField(blank=True)
    status = models.CharField(
        max_length=30, choices=VendorStatus.choices, default=VendorStatus.ACTIVE, db_index=True
    )

    class Meta:
        db_table = "vendors"
        verbose_name = "Vendor"
        verbose_name_plural = "Vendors"
        ordering = ["-created_at"]
        unique_together = [("tenant", "mobile")]
        indexes = [
            models.Index(fields=["tenant", "status"]),
            models.Index(fields=["tenant", "vendor_type"]),
            models.Index(fields=["tenant", "created_at"]),
        ]

    def __str__(self):
        return self.name


class BookingVendor(TenantBaseModel):
    booking = models.ForeignKey("bookings.Booking", on_delete=models.CASCADE, related_name="vendors", db_index=True)
    vendor = models.ForeignKey(Vendor, on_delete=models.CASCADE, db_index=True)
    agreed_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    status = models.CharField(max_length=30, default="ASSIGNED", db_index=True)

    class Meta:
        db_table = "booking_vendors"
        verbose_name = "Booking Vendor"
        verbose_name_plural = "Booking Vendors"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["tenant", "booking"]),
            models.Index(fields=["tenant", "status"]),
            models.Index(fields=["tenant", "created_at"]),
        ]

    def __str__(self):
        return f"{self.vendor.name} -> {self.booking.booking_number}"
