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
class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "users"
    search_fields = ["full_name", "email", "mobile"]
    filterset_fields = ["role", "is_active"]

    def get_queryset(self):
        tenant = self.request.tenant
        if self.request.user.role == "SUPER_ADMIN":
            from apps.users.models import User
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
