from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from apps.customers.models import Customer
from apps.customers.serializers import CustomerSerializer, MergeCustomerSerializer
from services.customer_service import CustomerService
from core.responses import ok, error
from core.exceptions import ValidationException
class CustomerViewSet(viewsets.ModelViewSet):
    serializer_class = CustomerSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "customers"
    search_fields = ["full_name", "mobile", "email"]
    filterset_fields = []

    def get_queryset(self):
        tenant = self.request.tenant
        return Customer.objects.filter(tenant=tenant, is_deleted=False).select_related(
            "created_by", "updated_by"
        )

    def perform_create(self, serializer):
        serializer.save(tenant=self.request.tenant)

    def perform_destroy(self, instance):
        from apps.bookings.models import Booking
        from apps.leads.models import Lead
        if Booking.objects.filter(customer=instance).exists():
            raise ValidationException("Cannot delete customer with existing bookings")
        if Lead.objects.filter(customer=instance).exists():
            raise ValidationException("Cannot delete customer with existing leads")
        instance.is_deleted = True
        instance.deleted_by = self.request.user
        instance.save()

    @action(detail=False, methods=["post"])
    def merge(self, request):
        serializer = MergeCustomerSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            service = CustomerService(request.tenant, request.user)
            primary = service.merge_customers(
                serializer.validated_data["primary_id"],
                serializer.validated_data["secondary_id"],
            )
            return ok(CustomerSerializer(primary).data, "Customers merged")
        except ValidationException as e:
            return error(e.message)
