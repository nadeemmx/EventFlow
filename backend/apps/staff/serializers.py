from rest_framework import serializers
from apps.staff.models import Staff
from core.validators import validate_mobile


class StaffSerializer(serializers.ModelSerializer):
    class Meta:
        model = Staff
        fields = [
            "id", "name", "mobile", "email",
            "designation", "joining_date", "status",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]
        extra_kwargs = {"mobile": {"validators": [validate_mobile]}}
