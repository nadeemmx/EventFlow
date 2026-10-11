import logging
from repositories.notification_repository import NotificationRepository
from services.base import BaseService
from core.choices import NotificationChannel, NotificationStatus
from gateway.messaging.email_provider import EmailProvider
from gateway.messaging.whatsapp_provider import WhatsAppProvider

logger = logging.getLogger(__name__)


class NotificationService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = NotificationRepository(self.tenant, self.user)
        self.email_provider = EmailProvider()
        self.whatsapp_provider = WhatsAppProvider()

    def get_repository(self):
        return self.repo

    def send(self, tenant, user, title, message, channel=NotificationChannel.IN_APP):
        notification = self.repo.create(
            tenant=tenant,
            user=user,
            title=title,
            message=message,
            channel=channel,
            status=NotificationStatus.PENDING,
        )
        if channel == NotificationChannel.EMAIL:
            result = self._send_email(user, title, message, tenant=tenant)
        elif channel == NotificationChannel.WHATSAPP:
            result = self._send_whatsapp(user, message, tenant=tenant)
        else:
            result = None
            notification.status = NotificationStatus.SENT

        if result is not None:
            notification.status = NotificationStatus.SENT if result.success else NotificationStatus.FAILED
        notification.save(update_fields=["status"])
        return notification

    def send_event_reminder(self, booking):
        from apps.settings.models import NotificationSettings
        n_settings = NotificationSettings.objects.filter(tenant=booking.tenant).first()
        if n_settings and n_settings.notify_on_booking and n_settings.email_enabled:
            customer = booking.customer
            if customer and customer.email:
                self.send(
                    tenant=booking.tenant,
                    user=None,
                    title=f"Event Reminder: {booking.event_type}",
                    message=f"Dear {customer.full_name}, your {booking.event_type} is scheduled on {booking.event_date}. - EventFlow",
                    channel=NotificationChannel.EMAIL,
                )
        return booking

    def _send_email(self, user, subject, message, tenant=None):
        from apps.settings.models import EmailSettings
        if not user or not user.email:
            logger.warning("No email address for user %s", user)
            return None
        email_settings = None
        scope_tenant = tenant or self.tenant
        if scope_tenant:
            email_settings = EmailSettings.objects.filter(tenant=scope_tenant, is_active=True).first()
        from_email = None
        if email_settings:
            from_email = email_settings.from_email
        return self.email_provider.send_email(to=user.email, subject=subject, body=message, from_email=from_email)

    def _send_whatsapp(self, user, message, tenant=None):
        if not user or not user.mobile:
            logger.warning("No mobile number for user %s", user)
            return None
        return self.whatsapp_provider.send_whatsapp(
            to=user.mobile, message=message, tenant=tenant or self.tenant
        )
