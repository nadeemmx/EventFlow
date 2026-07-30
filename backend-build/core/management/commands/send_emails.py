import logging
from django.core.mail import send_mail
from django.conf import settings
from django.core.management.base import BaseCommand
from django.utils import timezone
from core.choices import NotificationChannel, NotificationStatus

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Process email queue and send pending emails"

    def add_arguments(self, parser):
        parser.add_argument("--limit", type=int, default=50, help="Max emails to send")

    def handle(self, *args, **options):
        limit = options["limit"]
        from apps.notifications.models import Notification

        pending = Notification.objects.filter(
            status=NotificationStatus.PENDING,
            channel=NotificationChannel.EMAIL,
        ).select_related("user")[:limit]

        sent = 0
        for notification in pending:
            try:
                send_mail(
                    subject=notification.title or "Notification",
                    message=notification.message or "",
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[notification.user.email],
                    fail_silently=False,
                )
                notification.status = NotificationStatus.SENT
                notification.save(update_fields=["status"])
                sent += 1
            except Exception as e:
                logger.error("Failed to send email %s: %s", notification.id, e)
                notification.status = NotificationStatus.FAILED
                notification.save(update_fields=["status"])

        self.stdout.write(self.style.SUCCESS(f"Sent {sent} emails"))
