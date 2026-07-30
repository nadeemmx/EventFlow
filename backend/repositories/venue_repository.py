from repositories.base import BaseRepository
from apps.venues.models import Venue, VenueImage


class VenueRepository(BaseRepository):
    model = Venue


class VenueImageRepository(BaseRepository):
    model = VenueImage

    def get_venue_images(self, venue):
        return self.get_queryset().filter(venue=venue).order_by("display_order")
