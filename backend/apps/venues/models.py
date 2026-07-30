from django.db import models
from core.base_models import TenantBaseModel
from core.choices import VenueType, VenueStatus


class Venue(TenantBaseModel):
    name = models.CharField(max_length=255, db_index=True)
    venue_type = models.CharField(
        max_length=50, choices=VenueType.choices, db_index=True
    )
    capacity = models.IntegerField()
    description = models.TextField(blank=True)
    address = models.TextField(blank=True)
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    weekday_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    weekend_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    peak_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    status = models.CharField(
        max_length=30, choices=VenueStatus.choices, default=VenueStatus.ACTIVE, db_index=True
    )

    class Meta:
        db_table = "venues"
        verbose_name = "Venue"
        verbose_name_plural = "Venues"
        ordering = ["-created_at"]
        unique_together = [("tenant", "name")]
        indexes = [
            models.Index(fields=["tenant", "status"]),
            models.Index(fields=["tenant", "created_at"]),
        ]

    def __str__(self):
        return self.name


class VenueImage(TenantBaseModel):
    venue = models.ForeignKey(Venue, on_delete=models.CASCADE, related_name="images", db_index=True)
    image = models.ImageField(upload_to="venues/")
    display_order = models.IntegerField(default=0)

    class Meta:
        db_table = "venue_images"
        verbose_name = "Venue Image"
        verbose_name_plural = "Venue Images"
        ordering = ["display_order"]

    def __str__(self):
        return f"Image - {self.venue.name}"
