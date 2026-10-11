from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from django.http import FileResponse, HttpResponse
from django.db.models import Sum
from apps.invoices.models import Invoice
from apps.invoices.serializers import InvoiceSerializer, GenerateInvoiceSerializer
from services.invoice_service import InvoiceService
from core.responses import ok, error
from core.exceptions import ValidationException

class InvoiceViewSet(viewsets.ModelViewSet):
    serializer_class = InvoiceSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "invoices"
    search_fields = ["invoice_number", "booking__booking_number"]
    filterset_fields = ["booking"]

    def get_queryset(self):
        tenant = self.request.tenant
        return Invoice.objects.filter(tenant=tenant).select_related("booking__customer", "booking__venue", "booking__tenant")

    def perform_create(self, serializer):
        serializer.save(tenant=self.request.tenant)

    @action(detail=False, methods=["post"])
    def generate(self, request):
        serializer = GenerateInvoiceSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            service = InvoiceService(request.tenant, request.user)
            invoice = service.generate_invoice(serializer.validated_data["booking_id"])
            return ok(self.get_serializer(invoice).data, "Invoice generated", status=201)
        except ValidationException as e:
            return error(e.message)

    @action(detail=True, methods=["get"])
    def pdf(self, request, pk=None):
        invoice = self.get_object()
        return self._invoice_pdf_response(invoice)

    @action(detail=True, methods=["get"])
    def download(self, request, pk=None):
        invoice = self.get_object()
        return self._invoice_pdf_response(invoice)

    def _invoice_pdf_response(self, invoice):
        service = InvoiceService(self.request.tenant, self.request.user)
        pdf_content = service.generate_pdf(invoice)
        return HttpResponse(
            pdf_content,
            content_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={invoice.invoice_number}.pdf"},
        )

    @action(detail=True, methods=["post"])
    def email(self, request, pk=None):
        invoice = self.get_object()
        service = InvoiceService(request.tenant, request.user)
        service.email_invoice(invoice.id)
        return ok(None, "Invoice email sent")
