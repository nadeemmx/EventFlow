from repositories.base import BaseRepository
from apps.expenses.models import Expense


class ExpenseRepository(BaseRepository):
    model = Expense
