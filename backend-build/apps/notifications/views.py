from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from apps.notifications.serializers import NotificationSerializer
from apps.notifications.models import Notification
from core.responses import ok
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission


class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "notifications"

    def get_queryset(self):
        tenant = self.request.tenant
        return Notification.objects.filter(tenant=tenant).select_related(
            "user"
        ).order_by("-created_at")

    @action(detail=True, methods=["post"])
    def mark_read(self, request, pk=None):
        notification = self.get_object()
        notification.status = "READ"
        notification.save(update_fields=["status"])
        return ok(None, "Notification marked as read")
