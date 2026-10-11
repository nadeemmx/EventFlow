from django.core.validators import FileExtensionValidator
from rest_framework import serializers

from apps.privacy.models import PrivacyRequest
from core.validators import validate_pdf_file


class PrivacyRequestCreateSerializer(serializers.ModelSerializer):
    privacy_acknowledged = serializers.BooleanField(write_only=True, required=False)

    class Meta:
        model = PrivacyRequest
        fields = ["email", "full_name", "request_type", "description", "privacy_acknowledged"]
        extra_kwargs = {
            "full_name": {"required": False, "allow_blank": True, "max_length": 255},
            "description": {"required": False, "allow_blank": True, "allow_null": True},
        }

    def validate_email(self, value):
        return value.strip().lower()

    def validate_description(self, value):
        value = value or ""
        if len(value) > 5000:
            raise serializers.ValidationError("Please keep the description under 5000 characters.")
        return value


class PrivacyRequestAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = PrivacyRequest
        fields = ["id", "email", "full_name", "request_type", "description", "status",
                  "admin_notes", "created_at", "responded_at", "tenant", "user"]


class PrivacyRequestUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = PrivacyRequest
        fields = ["status", "admin_notes"]

    def validate_admin_notes(self, value):
        if len(value or "") > 5000:
            raise serializers.ValidationError("Notes must be under 5000 characters.")
        return value or ""


class ContactRequestSerializer(serializers.Serializer):
    SOURCE_CHOICES = [
        ("contact", "Contact form"),
        ("demo", "Demo request"),
        ("careers", "Careers"),
        ("status", "Status subscribe"),
    ]

    source = serializers.ChoiceField(choices=SOURCE_CHOICES, default="contact")
    name = serializers.CharField(max_length=255)
    email = serializers.EmailField()
    company = serializers.CharField(required=False, allow_blank=True, max_length=255)
    phone = serializers.CharField(required=False, allow_blank=True, max_length=32)
    subject = serializers.CharField(required=False, allow_blank=True, max_length=255)
    message = serializers.CharField(max_length=5000)
    privacy_acknowledged = serializers.BooleanField(default=False)
    marketing_opt_in = serializers.BooleanField(default=False)
    resume = serializers.FileField(
        required=False,
        allow_null=True,
        validators=[FileExtensionValidator(allowed_extensions=["pdf"]), validate_pdf_file],
    )

    def validate_email(self, value):
        return value.strip().lower()

    def validate_privacy_acknowledged(self, value):
        if not value:
            raise serializers.ValidationError(
                "You must confirm you have read the privacy notice before sending."
            )
        return value

    def validate_message(self, value):
        if not value.strip():
            raise serializers.ValidationError("Message cannot be empty.")
        if len(value) > 5000:
            raise serializers.ValidationError("Please keep the message under 5000 characters.")
        return value.strip()

    def validate_name(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError("Name cannot be empty.")
        return value

    def validate_phone(self, value):
        value = (value or "").strip()
        if value and len(value) > 32:
            raise serializers.ValidationError("Phone number is too long.")
        return value
