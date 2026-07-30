from rest_framework import serializers
from apps.inventory.models import InventoryItem, InventoryAllocation


class InventorySerializer(serializers.ModelSerializer):
    class Meta:
        model = InventoryItem
        fields = [
            "id", "item_name", "category", "total_quantity",
            "available_quantity", "status", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "available_quantity", "created_at", "updated_at"]


class AllocateInventorySerializer(serializers.Serializer):
    booking_id = serializers.IntegerField()
    inventory_item_id = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1)
