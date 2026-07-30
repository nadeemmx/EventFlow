from django.db import transaction
from repositories.booking_repository import BookingRepository, BookingHistoryRepository
from repositories.payment_repository import PaymentRepository
from repositories.audit_repository import AuditRepository
from repositories.inventory_repository import InventoryAllocationRepository
from services.base import BaseService
from core.choices import BookingStatus, PaymentType
from core.exceptions import ValidationException, ConflictException
from utils.booking_numbers import generate_booking_number


class BookingService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = BookingRepository(self.tenant, self.user)
        self.history_repo = BookingHistoryRepository(self.tenant, self.user)
        self.payment_repo = PaymentRepository(self.tenant, self.user)
        self.audit_repo = AuditRepository(self.tenant, self.user)
        self.inventory_alloc_repo = InventoryAllocationRepository(self.tenant, self.user)

    def get_repository(self):
        return self.repo

    @transaction.atomic
    def create_booking(self, data):
        venue = data.get("venue")
        event_date = data.get("event_date")
        guest_count = data.get("guest_count", 0)
        if venue and event_date:
            if guest_count > venue.capacity:
                raise ValidationException("Guest count exceeds venue capacity")
            self.repo.lock_venue_for_date(venue, event_date)
            if not self.repo.check_availability(venue, event_date):
                raise ConflictException("Venue is already booked on this date")
        data["booking_number"] = data.get("booking_number", generate_booking_number())
        booking = self.repo.create(**data)
        self.history_repo.create(
            booking=booking, new_status=BookingStatus.DRAFT,
        )
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="BOOKINGS", action="CREATE",
            record_id=booking.id,
        )
        return booking

    @transaction.atomic
    def confirm_booking(self, booking_id):
        booking = self.repo.get_for_update(booking_id)
        if booking.status != BookingStatus.DRAFT:
            raise ValidationException("Only draft bookings can be confirmed")
        self.repo.lock_venue_for_date(booking.venue, booking.event_date)
        if not self.repo.check_availability(booking.venue, booking.event_date, booking.id):
            raise ConflictException("Venue is already booked on this date")
        if booking.advance_amount <= 0:
            raise ValidationException("Advance payment required for confirmation")
        old_status = booking.status
        booking.status = BookingStatus.CONFIRMED
        booking.save(update_fields=["status"])
        self.history_repo.create(booking=booking, old_status=old_status, new_status=BookingStatus.CONFIRMED)
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="BOOKINGS", action="CONFIRM",
            record_id=booking.id,
            old_data=f"{{'status': '{old_status}'}}",
            new_data=f"{{'status': 'CONFIRMED'}}",
        )
        return booking

    @transaction.atomic
    def cancel_booking(self, booking_id, remarks=""):
        booking = self.repo.get_for_update(booking_id)
        if booking.status in [BookingStatus.CANCELLED, BookingStatus.COMPLETED]:
            raise ValidationException("Cannot cancel this booking")
        old_status = booking.status
        booking.status = BookingStatus.CANCELLED
        booking.remarks = remarks
        booking.save(update_fields=["status", "remarks"])
        self.history_repo.create(booking=booking, old_status=old_status, new_status=BookingStatus.CANCELLED, remarks=remarks)
        self.inventory_alloc_repo.get_queryset().filter(booking=booking).delete()
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="BOOKINGS", action="CANCEL",
            record_id=booking.id,
            old_data=f"{{'status': '{old_status}'}}",
            new_data=f"{{'status': 'CANCELLED'}}",
        )
        return booking

    def get_timeline(self, booking_id):
        booking = self.repo.get_by_id(booking_id)
        return self.history_repo.get_queryset().filter(booking=booking)

    def get_calendar(self, month, year, venue_id=None):
        return self.repo.get_calendar_bookings(month, year, venue_id)

    @transaction.atomic
    def mark_in_progress(self, booking_id):
        booking = self.repo.get_for_update(booking_id)
        if booking.status != BookingStatus.CONFIRMED:
            raise ValidationException("Only confirmed bookings can be marked in progress")
        old_status = booking.status
        booking.status = BookingStatus.IN_PROGRESS
        booking.save(update_fields=["status"])
        self.history_repo.create(booking=booking, old_status=old_status, new_status=BookingStatus.IN_PROGRESS)
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="BOOKINGS", action="MARK_IN_PROGRESS",
            record_id=booking.id,
            old_data=f"{{'status': '{old_status}'}}",
            new_data=f"{{'status': 'IN_PROGRESS'}}",
        )
        return booking

    @transaction.atomic
    def mark_completed(self, booking_id):
        booking = self.repo.get_for_update(booking_id)
        if booking.status != BookingStatus.IN_PROGRESS:
            raise ValidationException("Only in-progress bookings can be marked completed")
        old_status = booking.status
        booking.status = BookingStatus.COMPLETED
        booking.save(update_fields=["status"])
        self.history_repo.create(booking=booking, old_status=old_status, new_status=BookingStatus.COMPLETED)
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="BOOKINGS", action="MARK_COMPLETED",
            record_id=booking.id,
            old_data=f"{{'status': '{old_status}'}}",
            new_data=f"{{'status': 'COMPLETED'}}",
        )
        return booking

    @transaction.atomic
    def update_booking_status_from_payments(self, booking):
        total = booking.total_amount
        paid = self.payment_repo.get_total_paid(booking)
        if paid >= total and booking.status == BookingStatus.CONFIRMED:
            booking = self.repo.get_for_update(booking.id)
            paid = self.payment_repo.get_total_paid(booking)
            if paid >= total and booking.status == BookingStatus.CONFIRMED:
                booking.status = BookingStatus.COMPLETED
                booking.save(update_fields=["status"])
                self.history_repo.create(booking=booking, new_status=BookingStatus.COMPLETED)
