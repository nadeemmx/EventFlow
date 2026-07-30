from repositories.base import BaseRepository
from apps.tenants.models import Tenant, TenantSettings


class TenantRepository(BaseRepository):
    model = Tenant

    def get_queryset(self):
        return self.model.objects.all()

    def get_by_email(self, email):
        return self.model.objects.filter(email=email).first()

    def get_settings(self, tenant):
        settings, _ = TenantSettings.objects.get_or_create(tenant=tenant)
        return settings
