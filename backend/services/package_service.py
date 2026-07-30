from repositories.package_repository import PackageRepository, PackageItemRepository
from services.base import BaseService


class PackageService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = PackageRepository(self.tenant, self.user)

    def get_repository(self):
        return self.repo
