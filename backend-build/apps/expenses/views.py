from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from apps.expenses.serializers import ExpenseSerializer
from apps.expenses.models import Expense


class ExpenseViewSet(viewsets.ModelViewSet):
    serializer_class = ExpenseSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "expenses"
    filterset_fields = ["expense_category"]

    def get_queryset(self):
        tenant = self.request.tenant
        return Expense.objects.filter(tenant=tenant, is_deleted=False).select_related(
            "created_by"
        )

    def perform_create(self, serializer):
        serializer.save(tenant=self.request.tenant, created_by=self.request.user)

    def perform_destroy(self, instance):
        from django.utils.timezone import now
        instance.is_deleted = True
        instance.deleted_at = now()
        instance.deleted_by = self.request.user
        instance.save(update_fields=["is_deleted", "deleted_at", "deleted_by"])
