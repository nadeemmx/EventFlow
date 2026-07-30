from rest_framework import serializers
from apps.venues.models import Venue, VenueImage


class VenueSerializer(serializers.ModelSerializer):
    class Meta:
        model = Venue
        fields = [
            "id", "name", "venue_type", "capacity", "description",
            "address", "latitude", "longitude", "weekday_price",
            "weekend_price", "peak_price", "status", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class VenueImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = VenueImage
        fields = ["id", "venue", "image", "display_order", "created_at"]
        read_only_fields = ["id", "created_at"]
