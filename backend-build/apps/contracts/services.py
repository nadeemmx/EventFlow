from django.utils import timezone
from apps.contracts.models import Contract
from apps.contracts.repositories import ContractRepository
from repositories.booking_repository import BookingRepository
from repositories.audit_repository import AuditRepository
from services.base import BaseService
from core.exceptions import ValidationException, ConflictException


class ContractService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = ContractRepository(self.tenant, self.user)
        self.booking_repo = BookingRepository(self.tenant, self.user)
        self.audit_repo = AuditRepository(self.tenant, self.user)

    def get_repository(self):
        return self.repo

    def _generate_contract_number(self):
        year = timezone.now().year
        last = Contract.objects.filter(
            contract_number__startswith=f"CTR-{year}-"
        ).order_by("contract_number").last()
        if last:
            last_num = int(last.contract_number.split("-")[-1])
            new_num = last_num + 1
        else:
            new_num = 1
        return f"CTR-{year}-{new_num:06d}"

    def _build_content(self, booking):
        lines = []
        lines.append("<h1>Event Service Contract</h1>")
        lines.append(f"<p><strong>Contract Number:</strong> {{contract_number}}</p>")
        lines.append(f"<hr>")
        lines.append(f"<h2>Booking Details</h2>")
        lines.append(f"<p><strong>Booking Number:</strong> {booking.booking_number}</p>")
        lines.append(f"<p><strong>Event Type:</strong> {booking.event_type}</p>")
        lines.append(f"<p><strong>Event Date:</strong> {booking.event_date}</p>")
        lines.append(f"<p><strong>Guest Count:</strong> {booking.guest_count}</p>")
        if booking.customer:
            lines.append(f"<h2>Customer Information</h2>")
            lines.append(f"<p><strong>Name:</strong> {booking.customer.full_name}</p>")
            lines.append(f"<p><strong>Mobile:</strong> {booking.customer.mobile}</p>")
            lines.append(f"<p><strong>Email:</strong> {booking.customer.email or 'N/A'}</p>")
            if booking.customer.address:
                lines.append(f"<p><strong>Address:</strong> {booking.customer.address}</p>")
        if booking.venue:
            lines.append(f"<h2>Venue Information</h2>")
            lines.append(f"<p><strong>Name:</strong> {booking.venue.name}</p>")
            if booking.venue.address:
                lines.append(f"<p><strong>Address:</strong> {booking.venue.address}</p>")
        if booking.package:
            lines.append(f"<h2>Package Details</h2>")
            lines.append(f"<p><strong>Package:</strong> {booking.package.name}</p>")
        lines.append(f"<h2>Payment Terms</h2>")
        lines.append(f"<p><strong>Total Amount:</strong> {booking.total_amount}</p>")
        lines.append(f"<p><strong>Advance Amount:</strong> {booking.advance_amount}</p>")
        lines.append(f"<p>Full payment must be completed before the event date.</p>")
        lines.append(f"<h2>Cancellation Policy</h2>")
        lines.append(f"<p>Cancellations made more than 30 days before the event date will receive a full refund minus processing fees.</p>")
        lines.append(f"<p>Cancellations made 15-30 days before the event date will receive a 50% refund.</p>")
        lines.append(f"<p>Cancellations made less than 15 days before the event date are non-refundable.</p>")
        return "\n".join(lines)

    def generate_contract(self, booking_id, valid_from=None, valid_until=None, notes=""):
        booking = self.booking_repo.get_by_id(booking_id)
        existing = self.repo.get_queryset().filter(booking=booking).first()
        if existing:
            raise ConflictException("A contract already exists for this booking")
        contract_number = self._generate_contract_number()
        content = self._build_content(booking)
        contract = self.repo.create(
            booking=booking,
            contract_number=contract_number,
            content=content,
            valid_from=valid_from,
            valid_until=valid_until,
            notes=notes,
        )
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="CONTRACTS", action="GENERATE",
            record_id=contract.id,
            new_data=f"{{'contract_number': '{contract_number}', 'booking_id': {booking_id}}}",
        )
        return contract

    def sign_contract(self, contract_id, signed_by_name, signed_by_designation):
        contract = self.repo.get_by_id(contract_id)
        if contract.status != "DRAFT":
            raise ValidationException("Only draft contracts can be signed")
        contract.status = "SIGNED"
        contract.signed_date = timezone.now()
        contract.signed_by_name = signed_by_name
        contract.signed_by_designation = signed_by_designation
        contract.save()
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="CONTRACTS", action="SIGN",
            record_id=contract.id,
        )
        return contract

    def cancel_contract(self, contract_id):
        contract = self.repo.get_by_id(contract_id)
        if contract.status in ("SIGNED", "CANCELLED"):
            raise ValidationException("Cannot cancel this contract")
        old_status = contract.status
        contract.status = "CANCELLED"
        contract.save()
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="CONTRACTS", action="CANCEL",
            record_id=contract.id,
            old_data=f"{{'status': '{old_status}'}}",
            new_data=f"{{'status': 'CANCELLED'}}",
        )
        return contract

    def regenerate_contract(self, contract_id):
        contract = self.repo.get_by_id(contract_id)
        booking = contract.booking
        contract.content = self._build_content(booking)
        contract.save()
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="CONTRACTS", action="REGENERATE",
            record_id=contract.id,
        )
        return contract
