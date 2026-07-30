from repositories.base import BaseRepository
from apps.audit_logs.models import AuditLog


class AuditRepository(BaseRepository):
    model = AuditLog

    def get_queryset(self):
        return self.model.objects.all()

    def log(self, tenant, user, module, action, record_id=None, old_data="", new_data="", ip_address=""):
        return self.model.objects.create(
            tenant=tenant,
            user=user,
            module=module,
            action=action,
            record_id=record_id,
            old_data=old_data,
            new_data=new_data,
            ip_address=ip_address,
        )
