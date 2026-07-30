from rest_framework import serializers
from apps.tenants.models import Tenant, TenantSettings


class TenantSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tenant
        fields = [
            "id", "business_name", "owner_name", "email", "mobile",
            "address", "gst_number", "logo", "subscription_plan",
            "subscription_status", "status", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "subscription_status"]


class TenantSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = TenantSettings
        exclude = ["tenant"]
