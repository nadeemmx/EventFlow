from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated, AllowAny
from apps.tenants.serializers import TenantSerializer, TenantSettingsSerializer
from apps.tenants.models import Tenant
from services.tenant_service import TenantService
from core.responses import ok, error
from core.exceptions import ValidationException
from permissions.module_access import ModuleAccessPermission


class TenantViewSet(viewsets.GenericViewSet):
    serializer_class = TenantSerializer
    permission_classes = [IsAuthenticated]
    module_name = "tenants"

    def get_permissions(self):
        if self.action == "create":
            return [AllowAny()]
        return [IsAuthenticated(), ModuleAccessPermission()]

    def get_queryset(self):
        return Tenant.objects.all().select_related("subscription_plan")

    def get_object(self):
        tenant = self.request.tenant
        self.check_object_permissions(self.request, tenant)
        return tenant

    def create(self, request):
        from apps.subscriptions.models import SubscriptionPlan
        from apps.tenants.models import TenantSettings
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        tenant = serializer.save()
        default_plan = SubscriptionPlan.objects.filter(status="ACTIVE").first()
        if default_plan:
            tenant.subscription_plan = default_plan
            tenant.save()
        TenantSettings.objects.create(tenant=tenant)
        return ok(TenantSerializer(tenant).data, "Tenant created", status=201)

    def list(self, request):
        tenants = Tenant.objects.all().select_related("subscription_plan")
        page = self.paginate_queryset(tenants)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(tenants, many=True)
        return ok(serializer.data)

    def retrieve(self, request, *args, **kwargs):
        tenant = self.get_object()
        serializer = self.get_serializer(tenant)
        return ok(serializer.data)

    def update(self, request, *args, **kwargs):
        tenant = self.get_object()
        service = TenantService(tenant, request.user)
        updated = service.update_tenant(request.data)
        serializer = self.get_serializer(updated)
        return ok(serializer.data)

    def partial_update(self, request, *args, **kwargs):
        return self.update(request, *args, **kwargs)

    def settings(self, request):
        tenant = request.tenant
        settings = tenant.settings if hasattr(tenant, "settings") else None
        if not settings:
            from apps.tenants.models import TenantSettings
            settings = TenantSettings.objects.create(tenant=tenant)
        serializer = TenantSettingsSerializer(settings)
        return ok(serializer.data)
