from django.db import transaction
from repositories.base import BaseRepository
from repositories.audit_repository import AuditRepository
from repositories.user_repository import UserRepository
from services.base import BaseService
from core.choices import UserRole
from core.exceptions import ValidationException, ConflictException
from core.cache import CacheService, build_cache_key

from apps.settings.models import (
    PaymentGatewaySettings, WhatsAppSettings, EmailSettings,
    InvoiceSettings, BookingSettings, NotificationSettings,
    SecuritySettings, BrandingSettings,
)
from apps.settings.repositories import (
    PaymentGatewaySettingsRepository, WhatsAppSettingsRepository,
    EmailSettingsRepository, InvoiceSettingsRepository,
    BookingSettingsRepository, NotificationSettingsRepository,
    SecuritySettingsRepository, BrandingSettingsRepository,
)
from apps.tenants.models import Tenant
from apps.subscriptions.models import Subscription


MODEL_DEFAULTS = {
    PaymentGatewaySettings: {
        "gateway": "CASH", "api_key": "", "api_secret": "",
        "webhook_secret": "", "is_active": False, "environment": "test",
    },
    WhatsAppSettings: {
        "provider": "twilio", "api_key": "", "phone_number_id": "",
        "business_account_id": "", "webhook_verify_token": "",
        "is_active": False, "send_notifications": True,
    },
    EmailSettings: {
        "smtp_host": "", "smtp_port": 587, "smtp_username": "",
        "smtp_password": "", "from_email": "", "from_name": "",
        "use_tls": True, "use_ssl": False, "is_active": False,
    },
    InvoiceSettings: {
        "prefix": "INV", "next_number": 1, "footer_text": "",
        "payment_terms": "", "gst_enabled": True, "gst_rate": 18.00,
        "show_gst": True, "template": "standard", "due_days": 30,
        "late_payment_penalty": 0.00, "currency": "INR",
    },
    BookingSettings: {
        "tentative_validity_hours": 48, "auto_confirm": False,
        "buffer_days": 0, "max_advance_days": 365, "max_refund_days": 7,
        "allow_partial_payment": True, "deposit_percentage": 25.00,
        "cancellation_policy": "", "require_full_payment_days": 7,
    },
    NotificationSettings: {
        "notify_on_booking": True, "notify_on_payment": True,
        "notify_on_cancellation": True, "notify_on_checkin": False,
        "notify_on_lead": True, "email_enabled": True,
        "whatsapp_enabled": False, "sms_enabled": False,
        "notify_admin_only": False, "daily_digest": False,
        "reminder_hours": 24,
    },
    SecuritySettings: {
        "two_factor_enabled": False, "session_timeout_minutes": 120,
        "password_min_length": 8, "require_special_char": True,
        "require_number": True, "require_uppercase": True,
        "max_login_attempts": 5, "ip_whitelist_enabled": False,
        "allowed_ips": "", "allowed_domains": "",
    },
    BrandingSettings: {
        "primary_color": "#0F172A", "secondary_color": "#F59E0B",
        "accent_color": "#10B981", "custom_domain": "",
        "custom_css": "", "custom_js": "",
    },
}


class SettingsService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        if not self.tenant:
            from core.exceptions import ValidationException
            raise ValidationException("Tenant context is required for settings operations")
        self.pg_repo = PaymentGatewaySettingsRepository(self.tenant, self.user)
        self.whatsapp_repo = WhatsAppSettingsRepository(self.tenant, self.user)
        self.email_repo = EmailSettingsRepository(self.tenant, self.user)
        self.invoice_repo = InvoiceSettingsRepository(self.tenant, self.user)
        self.booking_repo = BookingSettingsRepository(self.tenant, self.user)
        self.notification_repo = NotificationSettingsRepository(self.tenant, self.user)
        self.security_repo = SecuritySettingsRepository(self.tenant, self.user)
        self.branding_repo = BrandingSettingsRepository(self.tenant, self.user)
        self.user_repo = UserRepository(self.tenant, self.user)
        self.audit_repo = AuditRepository(self.tenant, self.user)

    def get_repository(self):
        return self.pg_repo

    def _get_or_create(self, model, repo):
        instance = repo.get_queryset().first()
        if instance is None:
            defaults = MODEL_DEFAULTS.get(model, {})
            instance = model.objects.create(tenant=self.tenant, **defaults)
        return instance

    def _build_settings_cache_key(self, prefix):
        return build_cache_key("settings", prefix, self.tenant.id)

    def _get_cached_settings(self, prefix, model, repo):
        if not self.tenant:
            return self._get_or_create(model, repo)
        cache_key = self._build_settings_cache_key(prefix)
        return CacheService.get_or_set(cache_key, lambda: self._get_or_create(model, repo), CacheService.SETTINGS_TTL)

    def _invalidate_settings_cache(self):
        if self.tenant:
            CacheService.clear()

    def _update_settings(self, model, repo, serializer, audit_action):
        instance = self._get_or_create(model, repo)
        # Redact sensitive encrypted fields before logging
        sensitive_fields = {"api_key", "api_secret", "webhook_secret", "smtp_password", "phone_number_id", "business_account_id", "webhook_verify_token"}
        old_data = str({
            f: "***REDACTED***" if f in sensitive_fields else getattr(instance, f)
            for f in serializer.validated_data
        })
        instance = repo.update(instance, **serializer.validated_data)
        new_data = str({
            f: "***REDACTED***" if f in sensitive_fields else v
            for f, v in serializer.validated_data.items()
        })
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="SETTINGS", action=audit_action,
            record_id=instance.id,
            old_data=old_data,
            new_data=new_data,
        )
        return instance

    def get_payment_gateway_settings(self):
        return self._get_cached_settings("payment_gateway", PaymentGatewaySettings, self.pg_repo)

    def update_payment_gateway_settings(self, data):
        from apps.settings.serializers import PaymentGatewaySettingsSerializer
        instance = self._get_or_create(PaymentGatewaySettings, self.pg_repo)
        serializer = PaymentGatewaySettingsSerializer(instance, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        result = self._update_settings(
            PaymentGatewaySettings, self.pg_repo, serializer, "UPDATE_PAYMENT_GATEWAY"
        )
        self._invalidate_settings_cache()
        return result

    def get_whatsapp_settings(self):
        return self._get_cached_settings("whatsapp", WhatsAppSettings, self.whatsapp_repo)

    def update_whatsapp_settings(self, data):
        from apps.settings.serializers import WhatsAppSettingsSerializer
        instance = self._get_or_create(WhatsAppSettings, self.whatsapp_repo)
        serializer = WhatsAppSettingsSerializer(instance, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        result = self._update_settings(
            WhatsAppSettings, self.whatsapp_repo, serializer, "UPDATE_WHATSAPP"
        )
        self._invalidate_settings_cache()
        return result

    def get_email_settings(self):
        return self._get_cached_settings("email", EmailSettings, self.email_repo)

    def update_email_settings(self, data):
        from apps.settings.serializers import EmailSettingsSerializer
        instance = self._get_or_create(EmailSettings, self.email_repo)
        serializer = EmailSettingsSerializer(instance, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        result = self._update_settings(
            EmailSettings, self.email_repo, serializer, "UPDATE_EMAIL"
        )
        self._invalidate_settings_cache()
        return result

    def get_invoice_settings(self):
        return self._get_cached_settings("invoice", InvoiceSettings, self.invoice_repo)

    def update_invoice_settings(self, data):
        from apps.settings.serializers import InvoiceSettingsSerializer
        instance = self._get_or_create(InvoiceSettings, self.invoice_repo)
        serializer = InvoiceSettingsSerializer(instance, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        result = self._update_settings(
            InvoiceSettings, self.invoice_repo, serializer, "UPDATE_INVOICE"
        )
        self._invalidate_settings_cache()
        return result

    def get_booking_settings(self):
        return self._get_cached_settings("booking", BookingSettings, self.booking_repo)

    def update_booking_settings(self, data):
        from apps.settings.serializers import BookingSettingsSerializer
        instance = self._get_or_create(BookingSettings, self.booking_repo)
        serializer = BookingSettingsSerializer(instance, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        result = self._update_settings(
            BookingSettings, self.booking_repo, serializer, "UPDATE_BOOKING"
        )
        self._invalidate_settings_cache()
        return result

    def get_notification_settings(self):
        return self._get_cached_settings("notification", NotificationSettings, self.notification_repo)

    def update_notification_settings(self, data):
        from apps.settings.serializers import NotificationSettingsSerializer
        instance = self._get_or_create(NotificationSettings, self.notification_repo)
        serializer = NotificationSettingsSerializer(instance, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        result = self._update_settings(
            NotificationSettings, self.notification_repo, serializer, "UPDATE_NOTIFICATION"
        )
        self._invalidate_settings_cache()
        return result

    def get_security_settings(self):
        return self._get_cached_settings("security", SecuritySettings, self.security_repo)

    def update_security_settings(self, data):
        from apps.settings.serializers import SecuritySettingsSerializer
        instance = self._get_or_create(SecuritySettings, self.security_repo)
        serializer = SecuritySettingsSerializer(instance, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        result = self._update_settings(
            SecuritySettings, self.security_repo, serializer, "UPDATE_SECURITY"
        )
        self._invalidate_settings_cache()
        return result

    def get_branding_settings(self):
        return self._get_cached_settings("branding", BrandingSettings, self.branding_repo)

    def update_branding_settings(self, data):
        from apps.settings.serializers import BrandingSettingsSerializer
        instance = self._get_or_create(BrandingSettings, self.branding_repo)
        serializer = BrandingSettingsSerializer(instance, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        result = self._update_settings(
            BrandingSettings, self.branding_repo, serializer, "UPDATE_BRANDING"
        )
        self._invalidate_settings_cache()
        return result

    def get_organization_settings(self):
        if self.tenant:
            cache_key = self._build_settings_cache_key("organization")
            return CacheService.get_or_set(cache_key, lambda: self.tenant, CacheService.SETTINGS_TTL)
        return self.tenant

    def update_organization_settings(self, data):
        from apps.settings.serializers import OrganizationSettingsSerializer
        serializer = OrganizationSettingsSerializer(self.tenant, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        old_data = str({f: getattr(self.tenant, f) for f in serializer.validated_data})
        instance = serializer.save()
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="SETTINGS", action="UPDATE_ORGANIZATION",
            record_id=instance.id,
            old_data=old_data,
            new_data=str(serializer.validated_data),
        )
        self._invalidate_settings_cache()
        return instance

    def get_profile(self):
        if self.user:
            cache_key = self._build_settings_cache_key("profile")
            return CacheService.get_or_set(cache_key, lambda: self.user, CacheService.SETTINGS_TTL)
        return self.user

    def update_profile(self, data):
        from apps.settings.serializers import ProfileSerializer
        serializer = ProfileSerializer(self.user, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        old_data = str({f: getattr(self.user, f) for f in serializer.validated_data})
        instance = serializer.save()
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="SETTINGS", action="UPDATE_PROFILE",
            record_id=instance.id,
            old_data=old_data,
            new_data=str(serializer.validated_data),
        )
        self._invalidate_settings_cache()
        return instance

    def get_user_list(self, page=1, page_size=20):
        return self.user_repo.list(page=page, page_size=page_size)

    def create_user(self, data):
        from apps.settings.serializers import UserSerializer
        serializer = UserSerializer(data=data)
        serializer.is_valid(raise_exception=True)
        existing = self.user_repo.get_by_email(serializer.validated_data["email"])
        if existing and existing.tenant_id == self.tenant.id:
            raise ConflictException("Email already exists in this tenant")
        user = serializer.save(tenant=self.tenant)
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="USERS", action="CREATE",
            record_id=user.id,
        )
        return user

    def update_user(self, user_id, data):
        from apps.settings.serializers import UserSerializer
        user = self.user_repo.get_by_id(user_id)
        old_role = user.role
        serializer = UserSerializer(user, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        instance = serializer.save()
        if "role" in serializer.validated_data and serializer.validated_data["role"] != old_role:
            self.audit_repo.log(
                tenant=self.tenant, user=self.user,
                module="USERS", action="ROLE_CHANGE",
                record_id=instance.id,
                old_data=f"{{'role': '{old_role}'}}",
                new_data=f"{{'role': '{instance.role}'}}",
            )
        return instance

    def delete_user(self, user_id):
        user = self.user_repo.get_by_id(user_id)
        if user.role == UserRole.OWNER:
            raise ValidationException("Cannot delete owner")
        self.user_repo.delete(user)
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="USERS", action="DELETE",
            record_id=user.id,
        )

    def activate_user(self, user_id):
        user = self.user_repo.get_by_id(user_id)
        return self.user_repo.update(user, is_active=True)

    def deactivate_user(self, user_id):
        user = self.user_repo.get_by_id(user_id)
        if user.role == UserRole.OWNER:
            raise ValidationException("Cannot deactivate owner")
        return self.user_repo.update(user, is_active=False)

    def get_role_choices(self):
        return [{"value": choice.value, "label": choice.label} for choice in UserRole]

    def get_current_subscription(self):
        sub = Subscription.objects.filter(tenant=self.tenant).order_by("-start_date").first()
        if not sub:
            return None
        return {
            "id": sub.id,
            "plan_name": sub.plan.plan_name if sub.plan else None,
            "plan_display": sub.plan.get_plan_name_display() if sub.plan else None,
            "start_date": sub.start_date,
            "end_date": sub.end_date,
            "billing_cycle": sub.billing_cycle,
            "status": sub.status,
            "max_users": sub.plan.max_users if sub.plan else 0,
            "max_venues": sub.plan.max_venues if sub.plan else 0,
        }
