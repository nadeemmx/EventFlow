from django.db import models
from core.base_models import TenantBaseModel


class Expense(TenantBaseModel):
    expense_category = models.CharField(max_length=255, db_index=True)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    expense_date = models.DateField(db_index=True)
    remarks = models.TextField(blank=True)

    class Meta:
        db_table = "expenses"
        verbose_name = "Expense"
        verbose_name_plural = "Expenses"
        ordering = ["-expense_date"]
        indexes = [
            models.Index(fields=["tenant", "expense_date"]),
            models.Index(fields=["tenant", "expense_category"]),
            models.Index(fields=["tenant", "created_at"]),
        ]

    def __str__(self):
        return f"{self.expense_category}: {self.amount}"
