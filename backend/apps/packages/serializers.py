from rest_framework import serializers
from apps.packages.models import Package, PackageItem


class PackageItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = PackageItem
        fields = ["id", "item_name", "quantity", "unit_price"]
        read_only_fields = ["id"]


class PackageSerializer(serializers.ModelSerializer):
    items = PackageItemSerializer(many=True, read_only=True)

    class Meta:
        model = Package
        fields = [
            "id", "name", "description", "base_price",
            "status", "items", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]
