from django.db import models
from repositories.base import BaseRepository
from apps.payments.models import Payment
from core.choices import PaymentType


class PaymentRepository(BaseRepository):
    model = Payment

    def get_total_paid(self, booking):
        result = self.get_queryset().filter(
            booking=booking, payment_type=PaymentType.PAYMENT
        ).aggregate(total=models.Sum("amount"))
        return result["total"] or 0

    def get_total_refunded(self, booking):
        result = self.get_queryset().filter(
            booking=booking, payment_type=PaymentType.REFUND
        ).aggregate(total=models.Sum("amount"))
        return result["total"] or 0
