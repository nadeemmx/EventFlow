from rest_framework import serializers
from apps.customers.models import Customer


class CustomerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Customer
        fields = [
            "id", "full_name", "mobile", "email",
            "address", "remarks", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class MergeCustomerSerializer(serializers.Serializer):
    primary_id = serializers.IntegerField()
    secondary_id = serializers.IntegerField()
