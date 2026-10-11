from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from apps.bookings.models import Booking, BookingHistory
from core.choices import BookingStatus


class Command(BaseCommand):
    help = "Expire tentative bookings older than configured validity"

    def handle(self, *args, **options):
        cutoff = timezone.now() - timedelta(hours=48)
        expired = Booking.objects.filter(
            status=BookingStatus.TENTATIVE,
            created_at__lte=cutoff,
        )
        count = 0
        for booking in expired:
            booking.status = BookingStatus.CANCELLED
            booking.save()
            BookingHistory.objects.create(
                tenant=booking.tenant,
                booking=booking,
                old_status=BookingStatus.TENTATIVE,
                new_status=BookingStatus.CANCELLED,
                remarks="Auto-cancelled (tentative expired)",
            )
            count += 1
        self.stdout.write(f"Expired {count} tentative bookings")
