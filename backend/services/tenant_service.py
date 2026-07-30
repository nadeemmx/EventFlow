from repositories.tenant_repository import TenantRepository
from repositories.audit_repository import AuditRepository
from services.base import BaseService


class TenantService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = TenantRepository(self.tenant, self.user)
        self.audit_repo = AuditRepository(None, self.user)

    def get_repository(self):
        return self.repo

    def get_tenant_detail(self):
        return self.repo.get_by_id(self.tenant.id)

    def update_tenant(self, data):
        tenant = self.repo.get_by_id(self.tenant.id)
        tenant = self.repo.update(tenant, **data)
        self.audit_repo.log(
            tenant=tenant, user=self.user,
            module="TENANT", action="UPDATE",
            record_id=tenant.id,
        )
        return tenant
