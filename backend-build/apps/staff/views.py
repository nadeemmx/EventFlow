from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from apps.staff.serializers import StaffSerializer
from apps.staff.models import Staff


class StaffViewSet(viewsets.ModelViewSet):
    serializer_class = StaffSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "staff"
    search_fields = ["name", "mobile", "email"]
    filterset_fields = ["status"]

    def get_queryset(self):
        tenant = self.request.tenant
        return Staff.objects.filter(tenant=tenant, is_deleted=False).select_related(
            "created_by"
        )

    def perform_create(self, serializer):
        serializer.save(tenant=self.request.tenant, created_by=self.request.user)

    def perform_destroy(self, instance):
        instance.is_deleted = True
        instance.deleted_by = self.request.user
        instance.save()
