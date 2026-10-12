from django.db import models
from django.core.management.base import BaseCommand
from django.utils import timezone
from apps.bookings.models import Booking
from apps.payments.models import Payment
from core.choices import BookingStatus, PaymentType


class Command(BaseCommand):
    help = "Update overdue payment statuses"

    def handle(self, *args, **options):
        today = timezone.now().date()
        confirmed = Booking.objects.filter(status=BookingStatus.CONFIRMED)
        count = 0
        for booking in confirmed:
            total_paid = Payment.objects.filter(
                booking=booking, payment_type=PaymentType.PAYMENT
            ).aggregate(total=models.Sum("amount"))["total"] or 0
            if booking.event_date < today and total_paid < booking.total_amount:
                booking.status = BookingStatus.COMPLETED
                booking.save()
                count += 1
        self.stdout.write(f"Updated {count} bookings")
