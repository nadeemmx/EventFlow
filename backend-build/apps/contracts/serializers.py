from rest_framework import serializers
from apps.contracts.models import Contract

class ContractSerializer(serializers.ModelSerializer):
    booking_number = serializers.SerializerMethodField()
    customer_name = serializers.SerializerMethodField()
    venue_name = serializers.SerializerMethodField()

    class Meta:
        model = Contract
        fields = [
            "id", "booking", "booking_number", "customer_name", "venue_name",
            "contract_number", "content", "status", "pdf_file",
            "valid_from", "valid_until", "signed_date",
            "signed_by_name", "signed_by_designation",
            "template_version", "notes", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "contract_number", "pdf_file", "created_at", "updated_at"]

    def get_booking_number(self, obj):
        return obj.booking.booking_number if obj.booking else None

    def get_customer_name(self, obj):
        return obj.booking.customer.full_name if obj.booking and obj.booking.customer else None

    def get_venue_name(self, obj):
        return obj.booking.venue.name if obj.booking and obj.booking.venue else None


class GenerateContractSerializer(serializers.Serializer):
    booking_id = serializers.IntegerField()
    valid_from = serializers.DateField(required=False)
    valid_until = serializers.DateField(required=False)
    notes = serializers.CharField(required=False, allow_blank=True)
