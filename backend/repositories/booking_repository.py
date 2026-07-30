from django.db import models, transaction
from repositories.base import BaseRepository
from apps.bookings.models import Booking, BookingHistory
from core.choices import BookingStatus


class BookingRepository(BaseRepository):
    model = Booking

    def lock_venue_for_date(self, venue, event_date):
        return list(
            self.model.objects.select_for_update().filter(
                venue=venue,
                event_date=event_date,
                status__in=[BookingStatus.CONFIRMED, BookingStatus.TENTATIVE],
                is_deleted=False,
            )
        )

    def check_availability(self, venue, event_date, exclude_id=None):
        qs = self.get_queryset().filter(
            venue=venue,
            event_date=event_date,
            status__in=[BookingStatus.CONFIRMED, BookingStatus.TENTATIVE],
        )
        if exclude_id:
            qs = qs.exclude(id=exclude_id)
        return not qs.exists()

    def get_calendar_bookings(self, month, year, venue_id=None):
        qs = self.get_queryset().filter(event_date__year=year, event_date__month=month)
        if venue_id:
            qs = qs.filter(venue_id=venue_id)
        return qs.select_related("customer", "venue", "package").order_by("event_date")


class BookingHistoryRepository(BaseRepository):
    model = BookingHistory
