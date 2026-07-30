from rest_framework.permissions import BasePermission
from core.choices import UserRole


class TenantScopedPermission(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated)

    def has_object_permission(self, request, view, obj):
        if request.user.role == UserRole.SUPER_ADMIN:
            return True
        tenant_id = getattr(request.user, "tenant_id", None)
        obj_tenant_id = getattr(obj, "tenant_id", None)
        return tenant_id is not None and obj_tenant_id == tenant_id


class ModulePermission(BasePermission):
    allowed_roles = []
    allowed_actions = ["list", "retrieve", "create", "update", "partial_update", "destroy"]

    def has_permission(self, request, view):
        if not super().has_permission(request, view):
            return False
        if request.user.role == UserRole.SUPER_ADMIN:
            return True
        if not self.allowed_roles:
            return True
        return request.user.role in self.allowed_roles

    def has_object_permission(self, request, view, obj):
        return self.has_permission(request, view)
