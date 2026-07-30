import logging
from django.core.management.base import BaseCommand
from django.utils import timezone
from core.choices import NotificationStatus

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Retry failed notifications"

    def add_arguments(self, parser):
        parser.add_argument(
            "--max-attempts", type=int, default=3, help="Max retry attempts per notification"
        )
        parser.add_argument("--limit", type=int, default=50, help="Max notifications to retry")

    def handle(self, *args, **options):
        max_attempts = options["max_attempts"]
        limit = options["limit"]
        from apps.notifications.models import Notification
        from services.notification_service import NotificationService

        failed = Notification.objects.filter(
            status=NotificationStatus.FAILED,
        ).select_related("user", "tenant")[:limit]

        retried = 0
        for notification in failed:
            try:
                service = NotificationService(tenant=notification.tenant)
                service.send(
                    tenant=notification.tenant,
                    user=notification.user,
                    title=notification.title,
                    message=notification.message,
                    channel=notification.channel,
                )
                retried += 1
                logger.info("Retry succeeded for notification %s", notification.id)
            except Exception as e:
                logger.warning("Retry failed for notification %s: %s", notification.id, e)

        self.stdout.write(self.style.SUCCESS(f"Retried {retried} notifications"))
