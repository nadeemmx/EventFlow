from django.db import transaction
from django.utils import timezone
from services.payment_service import PaymentService
from core.exceptions import ValidationException


class RefundService(PaymentService):
    @transaction.atomic
    def process_refund(self, booking_id, amount):
        booking = self.booking_repo.get_for_update(booking_id)
        total_paid = self.repo.get_total_paid(booking)
        if amount > total_paid:
            raise ValidationException("Refund amount exceeds total paid")
        refund = self.repo.create(
            booking=booking,
            amount=amount,
            payment_type="REFUND",
            payment_date=timezone.now().date(),
        )
        booking.status = "REFUNDED"
        booking.save(update_fields=["status"])
        return refund
