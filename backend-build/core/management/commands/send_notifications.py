import logging
from django.core.management.base import BaseCommand
from django.utils import timezone
from core.choices import NotificationStatus

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Send pending notifications via configured channels"

    def add_arguments(self, parser):
        parser.add_argument("--limit", type=int, default=50, help="Max notifications to process")

    def handle(self, *args, **options):
        limit = options["limit"]
        from apps.notifications.models import Notification
        from services.notification_service import NotificationService

        pending = Notification.objects.filter(
            status=NotificationStatus.PENDING,
        ).select_related("user", "tenant")[:limit]

        sent = 0
        for notification in pending:
            try:
                service = NotificationService(tenant=notification.tenant)
                service.send(
                    tenant=notification.tenant,
                    user=notification.user,
                    title=notification.title,
                    message=notification.message,
                    channel=notification.channel,
                )
                sent += 1
            except Exception as e:
                logger.error("Failed to send notification %s: %s", notification.id, e)

        self.stdout.write(self.style.SUCCESS(f"Sent {sent} notifications"))
