from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from apps.subscriptions.serializers import (
    SubscriptionPlanSerializer, SubscriptionSerializer, RenewSubscriptionSerializer,
)
from apps.subscriptions.models import Subscription, SubscriptionPlan
from services.subscription_service import SubscriptionService
from core.responses import ok, error, paginated
from core.exceptions import ValidationException


class SubscriptionViewSet(viewsets.GenericViewSet):
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "subscriptions"
    search_fields = ["plan__plan_name", "tenant__business_name"]
    filterset_fields = ["status", "billing_cycle", "plan"]

    def get_serializer_class(self):
        if self.action == "plans":
            return SubscriptionPlanSerializer
        return SubscriptionSerializer

    def get_queryset(self):
        tenant = self.request.tenant
        return Subscription.objects.filter(tenant=tenant).select_related("plan")

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return paginated(serializer.data, self.paginator)
        serializer = self.get_serializer(queryset, many=True)
        return ok(serializer.data)

    def retrieve(self, request, *args, **kwargs):
        subscription = self.get_object()
        return ok(self.get_serializer(subscription).data)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        subscription = serializer.save(tenant=request.tenant)
        return ok(self.get_serializer(subscription).data, "Subscription created", status=201)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        subscription = self.get_object()
        serializer = self.get_serializer(subscription, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        subscription = serializer.save()
        return ok(self.get_serializer(subscription).data, "Subscription updated")

    def destroy(self, request, *args, **kwargs):
        subscription = self.get_object()
        subscription.delete()
        return ok(None, "Subscription deleted")

    @action(detail=False, methods=["get"])
    def plans(self, request):
        plans = SubscriptionPlan.objects.filter(status="ACTIVE")
        serializer = SubscriptionPlanSerializer(plans, many=True)
        return ok(serializer.data)

    @action(detail=False, methods=["get"])
    def current(self, request):
        tenant = request.tenant
        service = SubscriptionService(tenant, request.user)
        sub = service.get_current(tenant)
        if sub:
            return ok(SubscriptionSerializer(sub).data)
        return ok(None, "No active subscription")

    @action(detail=False, methods=["get"])
    def history(self, request):
        tenant = request.tenant
        subs = Subscription.objects.filter(tenant=tenant).select_related("plan").order_by("-start_date")
        serializer = SubscriptionSerializer(subs, many=True)
        return ok(serializer.data)

    @action(detail=False, methods=["post"])
    def renew(self, request):
        serializer = RenewSubscriptionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            tenant = request.tenant
            service = SubscriptionService(tenant, request.user)
            sub = service.renew(
                tenant,
                serializer.validated_data["plan_id"],
                serializer.validated_data["billing_cycle"],
            )
            return ok(SubscriptionSerializer(sub).data, "Subscription renewed")
        except ValidationException as e:
            return error(e.message)
