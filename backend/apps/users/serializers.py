from rest_framework import serializers
from apps.users.models import User
from core.choices import UserRole
from core.validators import validate_password_strength, validate_mobile


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = User
        fields = [
            "id", "full_name", "email", "mobile", "role",
            "is_active", "last_login", "password", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "last_login", "created_at", "updated_at"]
        extra_kwargs = {"mobile": {"validators": [validate_mobile]}}

    def validate_password(self, value):
        if value:
            validate_password_strength(value)
        return value
