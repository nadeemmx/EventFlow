from rest_framework import serializers
from apps.vendors.models import Vendor, BookingVendor


class VendorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vendor
        fields = [
            "id", "name", "vendor_type", "mobile",
            "email", "address", "status", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class AssignVendorSerializer(serializers.Serializer):
    booking_id = serializers.IntegerField()
    vendor_id = serializers.IntegerField()
    agreed_amount = serializers.DecimalField(max_digits=12, decimal_places=2, default=0)
