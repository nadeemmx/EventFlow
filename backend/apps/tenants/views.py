from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from apps.tenants.serializers import TenantSerializer, TenantSettingsSerializer
from apps.tenants.models import Tenant
from services.tenant_service import TenantService
from core.responses import ok, error
from core.exceptions import ValidationException
from permissions.module_access import ModuleAccessPermission
from core.choices import TenantStatus


class TenantViewSet(viewsets.GenericViewSet):
    serializer_class = TenantSerializer
    permission_classes = [IsAuthenticated]
    module_name = "tenants"

    def get_permissions(self):
        return [IsAuthenticated(), ModuleAccessPermission()]

    def get_queryset(self):
        return Tenant.objects.all().select_related("subscription_plan")

    def get_object(self):
        pk = self.kwargs.get("pk")
        tenant = Tenant.objects.select_related("subscription_plan").filter(pk=pk).first()
        if not tenant:
            from core.exceptions import NotFoundException
            raise NotFoundException("Tenant not found")
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
        serializer = self.get_serializer(tenant, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        service = TenantService(tenant, request.user)
        updated = service.update_tenant(serializer.validated_data)
        serializer = self.get_serializer(updated)
        return ok(serializer.data)

    def partial_update(self, request, *args, **kwargs):
        return self.update(request, *args, **kwargs)

    @action(detail=True, methods=["post"])
    def activate(self, request, pk=None):
        tenant = self.get_object()
        tenant.status = TenantStatus.ACTIVE
        tenant.save(update_fields=["status", "updated_at"])
        return ok(TenantSerializer(tenant).data, "Tenant activated")

    @action(detail=True, methods=["post"])
    def suspend(self, request, pk=None):
        tenant = self.get_object()
        tenant.status = TenantStatus.SUSPENDED
        tenant.save(update_fields=["status", "updated_at"])
        return ok(TenantSerializer(tenant).data, "Tenant suspended")

    @action(detail=True, methods=["post"])
    def disable(self, request, pk=None):
        tenant = self.get_object()
        tenant.status = TenantStatus.INACTIVE
        tenant.save(update_fields=["status", "updated_at"])
        return ok(TenantSerializer(tenant).data, "Tenant disabled")

    def tenant_settings(self, request):
        tenant = request.tenant
        tenant_settings = tenant.settings if hasattr(tenant, "settings") else None
        if not tenant_settings:
            from apps.tenants.models import TenantSettings
            tenant_settings = TenantSettings.objects.create(tenant=tenant)
        serializer = TenantSettingsSerializer(tenant_settings)
        return ok(serializer.data)
