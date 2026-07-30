from repositories.customer_repository import CustomerRepository
from repositories.audit_repository import AuditRepository
from services.base import BaseService
from core.exceptions import ValidationException


class CustomerService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = CustomerRepository(self.tenant, self.user)
        self.audit_repo = AuditRepository(self.tenant, self.user)

    def get_repository(self):
        return self.repo

    def create_customer(self, **data):
        return self.repo.create(**data)

    def merge_customers(self, primary_id, secondary_id):
        primary = self.repo.get_by_id(primary_id)
        secondary = self.repo.get_by_id(secondary_id)
        if primary.id == secondary.id:
            raise ValidationException("Cannot merge customer with itself")
        from apps.bookings.models import Booking
        Booking.objects.filter(customer=secondary).update(customer=primary)
        from apps.leads.models import Lead
        Lead.objects.filter(customer=secondary).update(customer=primary)
        self.repo.delete(secondary)
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="CUSTOMERS", action="MERGE",
            record_id=primary.id,
            old_data=f"{{'merged_id': {secondary.id}}}",
            new_data=f"{{'primary_id': {primary.id}}}",
        )
        return primary
