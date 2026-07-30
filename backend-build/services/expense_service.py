from repositories.expense_repository import ExpenseRepository
from services.base import BaseService


class ExpenseService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = ExpenseRepository(self.tenant, self.user)

    def get_repository(self):
        return self.repo
