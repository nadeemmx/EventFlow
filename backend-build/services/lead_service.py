from repositories.lead_repository import LeadRepository, FollowUpRepository, QuotationRepository
from repositories.audit_repository import AuditRepository
from services.base import BaseService
from core.choices import LeadStatus, BookingStatus
from core.exceptions import ValidationException


class LeadService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = LeadRepository(self.tenant, self.user)
        self.audit_repo = AuditRepository(self.tenant, self.user)

    def get_repository(self):
        return self.repo

    def convert_lead(self, lead_id, venue_id=None):
        lead = self.repo.get_by_id(lead_id)
        if lead.lead_status == LeadStatus.CONVERTED:
            raise ValidationException("Lead already converted")
        lead.lead_status = LeadStatus.CONVERTED
        lead.save()
        from services.booking_service import BookingService
        from utils.booking_numbers import generate_booking_number
        from django.shortcuts import get_object_or_404
        from apps.venues.models import Venue
        bk_service = BookingService(self.tenant, self.user)
        venue = get_object_or_404(Venue, id=venue_id, tenant=self.tenant) if venue_id else None
        booking = bk_service.repo.create(
            tenant=self.tenant,
            booking_number=generate_booking_number(),
            customer=lead.customer,
            venue=venue,
            event_type=lead.event_type,
            event_date=lead.expected_event_date,
            guest_count=lead.expected_guest_count or 0,
            status=BookingStatus.DRAFT,
        )
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="LEADS", action="CONVERT",
            record_id=lead.id,
            new_data=f"{{'booking_id': {booking.id}}}",
        )
        return lead, booking

    def add_followup(self, lead_id, data):
        lead = self.repo.get_by_id(lead_id)
        fup_repo = FollowUpRepository(self.tenant, self.user)
        return fup_repo.create(lead=lead, **data)
