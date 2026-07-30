from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from apps.vendors.models import Vendor
from apps.vendors.serializers import VendorSerializer, AssignVendorSerializer
from services.vendor_service import VendorService
from core.responses import ok, error
from core.exceptions import ValidationException

class VendorViewSet(viewsets.ModelViewSet):
    serializer_class = VendorSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "vendors"
    search_fields = ["name", "mobile", "email"]
    filterset_fields = ["vendor_type", "status"]

    def get_queryset(self):
        tenant = self.request.tenant
        return Vendor.objects.filter(tenant=tenant, is_deleted=False).select_related(
            "created_by"
        )

    def perform_create(self, serializer):
        serializer.save(tenant=self.request.tenant, created_by=self.request.user)

    @action(detail=False, methods=["post"])
    def assign(self, request):
        serializer = AssignVendorSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            service = VendorService(request.tenant, request.user)
            bv = service.assign_to_booking(
                serializer.validated_data["booking_id"],
                serializer.validated_data["vendor_id"],
                serializer.validated_data.get("agreed_amount", 0),
            )
            return ok({"id": bv.id}, "Vendor assigned")
        except ValidationException as e:
            return error(e.message)
