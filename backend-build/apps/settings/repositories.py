from repositories.base import BaseRepository
from apps.settings.models import (
    PaymentGatewaySettings, WhatsAppSettings, EmailSettings,
    InvoiceSettings, BookingSettings, NotificationSettings,
    SecuritySettings, BrandingSettings,
)


class PaymentGatewaySettingsRepository(BaseRepository):
    model = PaymentGatewaySettings


class WhatsAppSettingsRepository(BaseRepository):
    model = WhatsAppSettings


class EmailSettingsRepository(BaseRepository):
    model = EmailSettings


class InvoiceSettingsRepository(BaseRepository):
    model = InvoiceSettings


class BookingSettingsRepository(BaseRepository):
    model = BookingSettings


class NotificationSettingsRepository(BaseRepository):
    model = NotificationSettings


class SecuritySettingsRepository(BaseRepository):
    model = SecuritySettings


class BrandingSettingsRepository(BaseRepository):
    model = BrandingSettings
