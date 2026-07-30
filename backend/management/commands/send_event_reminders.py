from django.core.management.base import BaseCommand
from django.utils import timezone
from apps.bookings.models import Booking
from core.choices import BookingStatus


class Command(BaseCommand):
    help = "Send reminders for upcoming events"

    def handle(self, *args, **options):
        tomorrow = timezone.now().date() + timezone.timedelta(days=1)
        upcoming = Booking.objects.filter(
            event_date=tomorrow,
            status__in=[BookingStatus.CONFIRMED, BookingStatus.TENTATIVE],
        )
        count = upcoming.count()
        self.stdout.write(f"Found {count} events for tomorrow")
