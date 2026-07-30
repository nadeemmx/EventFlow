from django.db import transaction
from core.exceptions import DomainException


class BaseService:
    def __init__(self, tenant=None, user=None):
        self.tenant = tenant
        self.user = user
        if not self.tenant and self.user:
            self.tenant = getattr(self.user, "tenant", None)

    def get_repository(self):
        raise NotImplementedError

    def validate_business_rules(self, **kwargs):
        pass

    @transaction.atomic
    def execute_in_transaction(self, fn, *args, **kwargs):
        return fn(*args, **kwargs)
