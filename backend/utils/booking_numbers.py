from django.utils import timezone
from core.constants import BOOKING_NUMBER_PREFIX


def generate_booking_number():
    year = timezone.now().year
    from apps.bookings.models import Booking
    last = Booking.objects.filter(
        booking_number__startswith=f"{BOOKING_NUMBER_PREFIX}-{year}"
    ).order_by("booking_number").last()
    if last:
        last_num = int(last.booking_number.split("-")[-1])
        new_num = last_num + 1
    else:
        new_num = 1
    return f"{BOOKING_NUMBER_PREFIX}-{year}-{new_num:06d}"
