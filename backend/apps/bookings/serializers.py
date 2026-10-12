from rest_framework import serializers
from apps.bookings.models import Booking, BookingHistory


def scope_fields_to_tenant(serializer, field_names):
    request = serializer.context.get("request")
    if request is None:
        return
    tenant = getattr(request, "tenant", None)
    if tenant is None:
        return
    for name in field_names:
        field = serializer.fields.get(name)
        queryset = getattr(field, "queryset", None) if field is not None else None
        if queryset is not None:
            field.queryset = queryset.filter(tenant=tenant)


class BookingSerializer(serializers.ModelSerializer):
    customer_name = serializers.SerializerMethodField()
    venue_name = serializers.SerializerMethodField()

    class Meta:
        model = Booking
        fields = [
            "id", "booking_number", "venue", "venue_name", "customer", "customer_name",
            "package", "event_type", "event_date", "guest_count", "total_amount",
            "advance_amount", "status", "remarks", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "booking_number", "created_at", "updated_at"]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        scope_fields_to_tenant(self, ("customer", "venue", "package"))

    def get_customer_name(self, obj):
        return obj.customer.full_name if obj.customer else None

    def get_venue_name(self, obj):
        return obj.venue.name if obj.venue else None


class BookingHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = BookingHistory
        fields = ["id", "booking", "old_status", "new_status", "remarks", "created_at"]
        read_only_fields = ["id", "created_at"]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        scope_fields_to_tenant(self, ("booking",))


class CalendarSerializer(serializers.Serializer):
    month = serializers.IntegerField()
    year = serializers.IntegerField()
    venue = serializers.IntegerField(required=False)
