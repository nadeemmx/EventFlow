from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from apps.subscriptions.models import Subscription
from apps.notifications.models import Notification


class Command(BaseCommand):
    help = "Send subscription expiry reminders"

    def handle(self, *args, **options):
        now = timezone.now().date()
        reminders = [30, 15, 7, 3, 1]
        for days in reminders:
            target_date = now + timedelta(days=days)
            expiring = Subscription.objects.filter(
                end_date=target_date,
                status__in=["ACTIVE", "TRIAL"],
            )
            for sub in expiring:
                Notification.objects.create(
                    tenant=sub.tenant,
                    title="Subscription Expiry Reminder",
                    message=f"Your subscription expires in {days} days",
                )
        self.stdout.write("Subscription reminders sent")
