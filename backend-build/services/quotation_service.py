from repositories.lead_repository import QuotationRepository
from repositories.booking_repository import BookingRepository, BookingHistoryRepository
from repositories.audit_repository import AuditRepository
from services.base import BaseService
from core.choices import BookingStatus
from core.exceptions import ValidationException
from utils.booking_numbers import generate_booking_number


class QuotationService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = QuotationRepository(self.tenant, self.user)
        self.booking_repo = BookingRepository(self.tenant, self.user)
        self.history_repo = BookingHistoryRepository(self.tenant, self.user)
        self.audit_repo = AuditRepository(self.tenant, self.user)

    def get_repository(self):
        return self.repo

    def accept_quotation(self, quotation_id):
        quotation = self.repo.get_by_id(quotation_id)
        if quotation.status not in ("SENT", "DRAFT"):
            raise ValidationException("Only sent or draft quotations can be accepted")
        booking = self.booking_repo.create(
            tenant=self.tenant,
            booking_number=generate_booking_number(),
            customer=quotation.customer,
            venue=quotation.venue,
            package=quotation.package,
            event_type=quotation.lead.event_type if quotation.lead else "CUSTOM",
            event_date=quotation.lead.expected_event_date if quotation.lead else None,
            guest_count=quotation.lead.expected_guest_count if quotation.lead else 0,
            total_amount=quotation.total_amount,
            status=BookingStatus.DRAFT,
        )
        quotation.status = "ACCEPTED"
        quotation.save()
        self.history_repo.create(
            booking=booking,
            new_status=BookingStatus.DRAFT,
            remarks=f"Created from quotation #{quotation.id}",
        )
        if quotation.lead:
            quotation.lead.lead_status = "CONVERTED"
            quotation.lead.save()
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="QUOTATIONS", action="ACCEPT",
            record_id=quotation.id,
            new_data=f"{{'booking_id': {booking.id}}}",
        )
        return booking
