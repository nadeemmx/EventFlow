from rest_framework import serializers
from apps.expenses.models import Expense


class ExpenseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Expense
        fields = [
            "id", "expense_category", "amount",
            "expense_date", "remarks", "created_at",
        ]
        read_only_fields = ["id", "created_at"]
