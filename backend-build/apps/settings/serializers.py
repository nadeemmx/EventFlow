from rest_framework import serializers
from apps.settings.models import (
    PaymentGatewaySettings, WhatsAppSettings, EmailSettings,
    InvoiceSettings, BookingSettings, NotificationSettings,
    SecuritySettings, BrandingSettings,
)
from apps.tenants.models import Tenant
from apps.users.models import User
from core.choices import UserRole


class PaymentGatewaySettingsSerializer(serializers.ModelSerializer):
    api_key = serializers.CharField(write_only=True)
    api_secret = serializers.CharField(write_only=True)
    webhook_secret = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = PaymentGatewaySettings
        fields = [
            "id", "gateway", "api_key", "api_secret", "webhook_secret",
            "is_active", "environment", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def update(self, instance, validated_data):
        for field in ["api_key", "api_secret", "webhook_secret"]:
            if field not in validated_data:
                validated_data[field] = getattr(instance, field)
        return super().update(instance, validated_data)


class WhatsAppSettingsSerializer(serializers.ModelSerializer):
    api_key = serializers.CharField(write_only=True, required=False)
    phone_number_id = serializers.CharField(write_only=True, required=False)
    business_account_id = serializers.CharField(write_only=True, required=False)
    webhook_verify_token = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = WhatsAppSettings
        fields = [
            "id", "provider", "api_key", "phone_number_id",
            "business_account_id", "webhook_verify_token",
            "is_active", "send_notifications", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def update(self, instance, validated_data):
        for field in ["api_key", "phone_number_id", "business_account_id", "webhook_verify_token"]:
            if field not in validated_data:
                validated_data[field] = getattr(instance, field)
        return super().update(instance, validated_data)


class EmailSettingsSerializer(serializers.ModelSerializer):
    smtp_password = serializers.CharField(write_only=True)

    class Meta:
        model = EmailSettings
        fields = [
            "id", "smtp_host", "smtp_port", "smtp_username",
            "smtp_password", "from_email", "from_name",
            "use_tls", "use_ssl", "is_active", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def update(self, instance, validated_data):
        if "smtp_password" not in validated_data:
            validated_data["smtp_password"] = getattr(instance, "smtp_password")
        return super().update(instance, validated_data)


class InvoiceSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = InvoiceSettings
        fields = [
            "id", "prefix", "next_number", "logo", "footer_text",
            "payment_terms", "gst_enabled", "gst_rate", "show_gst",
            "template", "due_days", "late_payment_penalty", "currency",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class BookingSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = BookingSettings
        fields = [
            "id", "tentative_validity_hours", "auto_confirm", "buffer_days",
            "max_advance_days", "max_refund_days", "allow_partial_payment",
            "deposit_percentage", "cancellation_policy",
            "require_full_payment_days", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class NotificationSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationSettings
        fields = [
            "id", "notify_on_booking", "notify_on_payment",
            "notify_on_cancellation", "notify_on_checkin", "notify_on_lead",
            "email_enabled", "whatsapp_enabled", "sms_enabled",
            "notify_admin_only", "daily_digest", "reminder_hours",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class SecuritySettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = SecuritySettings
        fields = [
            "id", "two_factor_enabled", "session_timeout_minutes",
            "password_min_length", "require_special_char", "require_number",
            "require_uppercase", "max_login_attempts", "ip_whitelist_enabled",
            "allowed_ips", "allowed_domains", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class BrandingSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = BrandingSettings
        fields = [
            "id", "primary_color", "secondary_color", "accent_color",
            "logo", "favicon", "custom_domain", "custom_css", "custom_js",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class OrganizationSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tenant
        fields = [
            "id", "business_name", "email", "mobile", "address", "gst_number",
            "logo",
        ]
        read_only_fields = ["id"]


class ProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "full_name", "email", "mobile"]
        read_only_fields = ["id"]


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = User
        fields = [
            "id", "full_name", "email", "mobile", "role", "is_active",
            "password", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def create(self, validated_data):
        password = validated_data.pop("password", None)
        user = super().create(validated_data)
        if password:
            user.set_password(password)
            user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop("password", None)
        user = super().update(instance, validated_data)
        if password:
            user.set_password(password)
            user.save()
        return user


class RoleSerializer(serializers.Serializer):
    value = serializers.CharField()
    label = serializers.CharField()


class SettingsSubscriptionSerializer(serializers.Serializer):
    id = serializers.IntegerField(read_only=True)
    plan_name = serializers.CharField(read_only=True)
    plan_display = serializers.CharField(read_only=True)
    start_date = serializers.DateField(read_only=True)
    end_date = serializers.DateField(read_only=True)
    billing_cycle = serializers.CharField(read_only=True)
    status = serializers.CharField(read_only=True)
    max_users = serializers.IntegerField(read_only=True)
    max_venues = serializers.IntegerField(read_only=True)
