from rest_framework import serializers
from apps.payments.models import Payment


class PaymentSerializer(serializers.ModelSerializer):
    booking_number = serializers.SerializerMethodField()

    class Meta:
        model = Payment
        fields = [
            "id", "booking", "booking_number", "amount", "payment_method",
            "payment_type", "transaction_reference",
            "payment_date", "notes", "created_at",
        ]
        read_only_fields = ["id", "payment_type", "created_at"]

    def get_booking_number(self, obj):
        return obj.booking.booking_number if obj.booking else None


class RefundSerializer(serializers.Serializer):
    payment_id = serializers.IntegerField()
