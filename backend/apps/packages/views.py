from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from apps.packages.models import Package
from apps.packages.serializers import PackageSerializer



class PackageViewSet(viewsets.ModelViewSet):
    serializer_class = PackageSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "packages"
    search_fields = ["name"]
    filterset_fields = ["status"]

    def get_queryset(self):
        tenant = self.request.tenant
        return Package.objects.filter(tenant=tenant, is_deleted=False).prefetch_related("items")

    def perform_create(self, serializer):
        serializer.save(tenant=self.request.tenant, created_by=self.request.user)
