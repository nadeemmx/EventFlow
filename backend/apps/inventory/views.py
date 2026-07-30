from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from apps.inventory.serializers import InventorySerializer, AllocateInventorySerializer
from apps.inventory.models import InventoryItem
from services.inventory_service import InventoryService
from core.responses import ok, error
from core.exceptions import ValidationException


class InventoryViewSet(viewsets.ModelViewSet):
    serializer_class = InventorySerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "inventory"
    search_fields = ["item_name"]
    filterset_fields = ["category", "status"]

    def get_queryset(self):
        tenant = self.request.tenant
        return InventoryItem.objects.filter(tenant=tenant, is_deleted=False).select_related(
            "created_by"
        )

    def perform_create(self, serializer):
        item = serializer.save(tenant=self.request.tenant, created_by=self.request.user)
        if item.available_quantity == 0:
            item.available_quantity = item.total_quantity
            item.save()

    @action(detail=False, methods=["post"])
    def allocate(self, request):
        serializer = AllocateInventorySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            service = InventoryService(request.tenant, request.user)
            allocation = service.allocate(
                serializer.validated_data["booking_id"],
                serializer.validated_data["inventory_item_id"],
                serializer.validated_data["quantity"],
            )
            return ok({"id": allocation.id}, "Inventory allocated")
        except ValidationException as e:
            return error(e.message)

    @action(detail=False, methods=["post"])
    def release(self, request):
        booking_id = request.data.get("booking_id")
        if not booking_id:
            return error("booking_id is required")
        service = InventoryService(request.tenant, request.user)
        service.release(booking_id)
        return ok(None, "Inventory released")
