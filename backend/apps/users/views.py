from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from apps.users.serializers import UserSerializer
from services.user_service import UserService
from core.responses import ok, error
from core.exceptions import ValidationException
from permissions.roles import IsOwner, IsSuperAdmin
from apps.users.models import User


class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "users"
    search_fields = ["full_name", "email", "mobile"]
    filterset_fields = ["role", "is_active"]

    def get_queryset(self):
        tenant = self.request.tenant
        if self.request.user.role == "SUPER_ADMIN":
            return User.objects.all()
        return User.objects.filter(tenant=tenant).select_related("tenant")

    def perform_create(self, serializer):
        tenant = self.request.tenant
        service = UserService(tenant, self.request.user)
        user = service.create_user({
            **serializer.validated_data,
            "tenant": tenant,
        })
        return user

    def perform_update(self, serializer):
        tenant = self.request.tenant
        service = UserService(tenant, self.request.user)
        service.update_user(serializer.instance.id, serializer.validated_data)

    def destroy(self, request, *args, **kwargs):
        """DELETE is irreversible, so it must name its target.

        The inherited ``ModelViewSet.destroy`` hard-deleted whoever the URL
        pointed at with no guard and no audit row — an automated RBAC sweep
        issued ``DELETE /users/1/`` and destroyed the Owner fixture
        (QA-TEST-REPORT-ROLES.md F-4). Requiring the caller to restate the
        account's email makes a blind sweep fail with a 400 instead of
        removing a person.
        """
        instance = self.get_object()
        confirm = request.query_params.get("confirm") or request.data.get("confirm")
        if not confirm or confirm.strip().lower() != instance.email.lower():
            return error(
                "Deletion is irreversible. Re-send with confirm set to the "
                "email of the account to delete.",
                status=400,
            )
        service = UserService(request.tenant, request.user)
        try:
            service.delete_user(instance.id)
        except ValidationException as e:
            return error(e.message)
        return ok(None, "User deleted")

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            user = self.perform_create(serializer)
            result = self.get_serializer(user).data
            return ok(result, "User created", status=201)
        except ValidationException as e:
            return error(e.message, status=400)

    @action(detail=True, methods=["post"])
    def activate(self, request, pk=None):
        tenant = request.tenant
        service = UserService(tenant, request.user)
        try:
            user = service.activate_user(pk)
            return ok(None, "User activated")
        except ValidationException as e:
            return error(e.message)

    @action(detail=True, methods=["post"])
    def deactivate(self, request, pk=None):
        tenant = request.tenant
        service = UserService(tenant, request.user)
        try:
            user = service.deactivate_user(pk)
            return ok(None, "User deactivated")
        except ValidationException as e:
            return error(e.message)
