from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from django.http import FileResponse
from apps.contracts.models import Contract
from apps.contracts.serializers import ContractSerializer, GenerateContractSerializer
from apps.contracts.services import ContractService
from core.responses import ok, error, paginated
from core.exceptions import ValidationException


class ContractViewSet(viewsets.ModelViewSet):
    serializer_class = ContractSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "contracts"
    search_fields = ["contract_number", "booking__booking_number"]
    filterset_fields = ["status"]

    def get_queryset(self):
        tenant = self.request.tenant
        return Contract.objects.filter(tenant=tenant, is_deleted=False).select_related(
            "booking__customer", "booking__venue"
        )

    def perform_create(self, serializer):
        serializer.save(tenant=self.request.tenant, created_by=self.request.user)

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return paginated(serializer.data, self.paginator)
        serializer = self.get_serializer(queryset, many=True)
        return ok(serializer.data)

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return ok(serializer.data)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        return ok(serializer.data, "Contract created", status=201)

    @action(detail=False, methods=["post"])
    def generate(self, request):
        serializer = GenerateContractSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        service = ContractService(request.tenant, request.user)
        try:
            contract = service.generate_contract(
                serializer.validated_data["booking_id"],
                serializer.validated_data.get("valid_from"),
                serializer.validated_data.get("valid_until"),
                serializer.validated_data.get("notes", ""),
            )
            return ok(self.get_serializer(contract).data, "Contract generated", status=201)
        except ValidationException as e:
            return error(e.message)

    @action(detail=True, methods=["get"])
    def pdf(self, request, pk=None):
        contract = self.get_object()
        if not contract.pdf_file:
            return error("No PDF file available")
        return FileResponse(contract.pdf_file.open(), content_type="application/pdf")

    @action(detail=True, methods=["post"])
    def sign(self, request, pk=None):
        service = ContractService(request.tenant, request.user)
        try:
            contract = service.sign_contract(
                pk,
                request.data.get("signed_by_name", ""),
                request.data.get("signed_by_designation", ""),
            )
            return ok(self.get_serializer(contract).data, "Contract signed")
        except ValidationException as e:
            return error(e.message)

    @action(detail=True, methods=["post"])
    def cancel(self, request, pk=None):
        service = ContractService(request.tenant, request.user)
        try:
            contract = service.cancel_contract(pk)
            return ok(self.get_serializer(contract).data, "Contract cancelled")
        except ValidationException as e:
            return error(e.message)
