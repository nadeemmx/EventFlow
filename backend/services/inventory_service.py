from django.db import transaction
from repositories.inventory_repository import InventoryRepository, InventoryAllocationRepository
from repositories.audit_repository import AuditRepository
from services.base import BaseService
from core.exceptions import ValidationException
from apps.bookings.models import Booking


class InventoryService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = InventoryRepository(self.tenant, self.user)
        self.alloc_repo = InventoryAllocationRepository(self.tenant, self.user)
        self.audit_repo = AuditRepository(self.tenant, self.user)

    def get_repository(self):
        return self.repo

    @transaction.atomic
    def allocate(self, booking_id, inventory_item_id, quantity):
        bookings = Booking.objects.all()
        if self.tenant:
            bookings = bookings.filter(tenant=self.tenant)
        if not bookings.filter(id=booking_id).exists():
            raise ValidationException("Booking not found")
        item = self.repo.get_for_update(inventory_item_id)
        if quantity > item.available_quantity:
            raise ValidationException("Insufficient available quantity")
        allocation = self.alloc_repo.create(
            booking_id=booking_id,
            inventory_item=item,
            allocated_quantity=quantity,
        )
        item.available_quantity -= quantity
        item.save(update_fields=["available_quantity"])
        return allocation

    @transaction.atomic
    def release(self, booking_id):
        allocations = self.alloc_repo.get_queryset().filter(booking_id=booking_id)
        for alloc in allocations:
            item = self.repo.get_for_update(alloc.inventory_item_id)
            item.available_quantity += alloc.allocated_quantity
            item.save(update_fields=["available_quantity"])
            alloc.delete()
