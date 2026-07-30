from django.db import models
from core.base_models import TenantBaseModel


class Package(TenantBaseModel):
    name = models.CharField(max_length=255, db_index=True)
    description = models.TextField(blank=True)
    base_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    status = models.CharField(max_length=30, default="ACTIVE", db_index=True)

    class Meta:
        db_table = "packages"
        verbose_name = "Package"
        verbose_name_plural = "Packages"
        ordering = ["-created_at"]
        unique_together = [("tenant", "name")]
        indexes = [
            models.Index(fields=["tenant", "status"]),
            models.Index(fields=["tenant", "created_at"]),
        ]

    def __str__(self):
        return self.name


class PackageItem(TenantBaseModel):
    package = models.ForeignKey(Package, on_delete=models.CASCADE, related_name="items", db_index=True)
    item_name = models.CharField(max_length=255)
    quantity = models.IntegerField(default=1)
    unit_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    class Meta:
        db_table = "package_items"
        verbose_name = "Package Item"
        verbose_name_plural = "Package Items"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["tenant", "package"]),
        ]

    def __str__(self):
        return f"{self.item_name} x {self.quantity}"
