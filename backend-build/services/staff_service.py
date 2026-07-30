from repositories.staff_repository import StaffRepository
from services.base import BaseService


class StaffService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = StaffRepository(self.tenant, self.user)

    def get_repository(self):
        return self.repo
