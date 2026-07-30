from django.db import models
from repositories.base import BaseRepository
from apps.inventory.models import InventoryItem, InventoryAllocation


class InventoryRepository(BaseRepository):
    model = InventoryItem


class InventoryAllocationRepository(BaseRepository):
    model = InventoryAllocation

    def get_allocated_quantity(self, inventory_item):
        result = self.get_queryset().filter(
            inventory_item=inventory_item
        ).aggregate(total=models.Sum("allocated_quantity"))
        return result["total"] or 0
