from rest_framework import serializers
from apps.customers.models import Customer
from core.validators import validate_mobile as validate_mobile_format


class CustomerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Customer
        fields = [
            "id", "full_name", "mobile", "email",
            "address", "remarks", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def validate_mobile(self, value):
        # Format first (QA-TEST-REPORT-ROLES.md F-5 — the validator existed in
        # core/validators.py but was wired to nothing, so "not-a-number-mgr"
        # was stored), then uniqueness. ``unique_together = [("tenant",
        # "mobile")]`` would otherwise reject a duplicate only at INSERT time,
        # surfacing as an IntegrityError 500 (QA-TEST-REPORT.md P1-2). Validate
        # up front, scoped to the caller's tenant, so the client gets a
        # field-level 400.
        validate_mobile_format(value)
        tenant = getattr(self.context.get("request"), "tenant", None)
        if tenant is None:
            return value
        qs = Customer.objects.filter(tenant=tenant, mobile=value)
        if self.instance is not None:
            qs = qs.exclude(pk=self.instance.pk)
        if qs.exists():
            raise serializers.ValidationError(
                "A customer with this mobile number already exists.")
        return value


class MergeCustomerSerializer(serializers.Serializer):
    primary_id = serializers.IntegerField()
    secondary_id = serializers.IntegerField()
