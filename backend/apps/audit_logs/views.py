from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from apps.audit_logs.models import AuditLog
from apps.audit_logs.serializers import AuditLogSerializer
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission


class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = AuditLogSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "audit_logs"
    filterset_fields = ["module", "action", "user"]

    def get_queryset(self):
        tenant = self.request.tenant
        return AuditLog.objects.filter(tenant=tenant).select_related("user").order_by("-created_at")
