from django.db import models
from core.base_models import TenantBaseModel
from core.choices import InventoryCategory


class InventoryItem(TenantBaseModel):
    item_name = models.CharField(max_length=255, db_index=True)
    category = models.CharField(
        max_length=100, choices=InventoryCategory.choices, default=InventoryCategory.CHAIRS, db_index=True
    )
    total_quantity = models.IntegerField(default=0)
    available_quantity = models.IntegerField(default=0)
    status = models.CharField(max_length=30, default="ACTIVE", db_index=True)

    class Meta:
        db_table = "inventory_items"
        verbose_name = "Inventory Item"
        verbose_name_plural = "Inventory Items"
        ordering = ["-created_at"]
        unique_together = [("tenant", "item_name")]
        indexes = [
            models.Index(fields=["tenant", "status"]),
            models.Index(fields=["tenant", "category"]),
            models.Index(fields=["tenant", "created_at"]),
        ]

    def __str__(self):
        return f"{self.item_name} ({self.available_quantity}/{self.total_quantity})"


class InventoryAllocation(TenantBaseModel):
    booking = models.ForeignKey(
        "bookings.Booking", on_delete=models.CASCADE, related_name="inventory_allocations", db_index=True
    )
    inventory_item = models.ForeignKey(
        InventoryItem, on_delete=models.CASCADE, related_name="allocations", db_index=True
    )
    allocated_quantity = models.IntegerField()

    class Meta:
        db_table = "inventory_allocations"
        verbose_name = "Inventory Allocation"
        verbose_name_plural = "Inventory Allocations"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["tenant", "booking"]),
            models.Index(fields=["tenant", "inventory_item"]),
        ]

    def __str__(self):
        return f"{self.inventory_item.item_name} x {self.allocated_quantity}"
