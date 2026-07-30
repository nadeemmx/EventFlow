from repositories.audit_repository import AuditRepository
from services.base import BaseService


class AuditService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = AuditRepository()

    def get_repository(self):
        return self.repo

    def log(self, module, action, record_id=None, old_data=None, new_data=None, ip_address=""):
        return self.repo.log(
            tenant=self.tenant,
            user=self.user,
            module=module,
            action=action,
            record_id=record_id,
            old_data=old_data,
            new_data=new_data,
            ip_address=ip_address,
        )
