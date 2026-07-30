from repositories.vendor_repository import VendorRepository, BookingVendorRepository
from repositories.audit_repository import AuditRepository
from services.base import BaseService
from core.exceptions import ValidationException


class VendorService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = VendorRepository(self.tenant, self.user)
        self.booking_vendor_repo = BookingVendorRepository(self.tenant, self.user)
        self.audit_repo = AuditRepository(self.tenant, self.user)

    def get_repository(self):
        return self.repo

    def assign_to_booking(self, booking_id, vendor_id, agreed_amount=0):
        from repositories.booking_repository import BookingRepository
        from core.choices import BookingStatus
        booking_repo = BookingRepository(self.tenant, self.user)
        booking = booking_repo.get_by_id(booking_id)
        if booking.status != BookingStatus.CONFIRMED:
            raise ValidationException("Vendor assignment requires confirmed booking")
        vendor = self.repo.get_by_id(vendor_id)
        return self.booking_vendor_repo.create(
            booking=booking,
            vendor=vendor,
            agreed_amount=agreed_amount,
        )
