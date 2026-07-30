from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from django.shortcuts import get_object_or_404
from apps.leads.models import Lead, FollowUp, Quotation, QuotationItem
from apps.leads.serializers import (LeadSerializer, FollowUpSerializer, QuotationListSerializer, QuotationDetailSerializer, CreateQuotationSerializer)
from services.lead_service import LeadService
from services.quotation_service import QuotationService
from core.responses import ok, error, paginated
from core.exceptions import ValidationException


class LeadViewSet(viewsets.ModelViewSet):
    serializer_class = LeadSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "leads"
    search_fields = ["customer__full_name", "customer__mobile"]
    filterset_fields = ["lead_status", "lead_source", "assigned_to"]

    def get_queryset(self):
        tenant = self.request.tenant
        return Lead.objects.filter(tenant=tenant, is_deleted=False).select_related("customer", "assigned_to")

    def perform_create(self, serializer):
        serializer.save(tenant=self.request.tenant, created_by=self.request.user)

    @action(detail=True, methods=["post"])
    def convert(self, request, pk=None):
        service = LeadService(request.tenant, request.user)
        try:
            venue_id = request.data.get("venue_id")
            lead, booking = service.convert_lead(pk, venue_id=venue_id)
            return ok(
                {"lead_id": lead.id, "booking_id": booking.id},
                "Lead converted to booking",
            )
        except ValidationException as e:
            return error(e.message)

    @action(detail=True, methods=["get"])
    def followups(self, request, pk=None):
        lead = self.get_object()
        fups = lead.followups.all().order_by("-followup_date")
        serializer = FollowUpSerializer(fups, many=True)
        return ok(serializer.data)

    @action(detail=True, methods=["post"])
    def add_followup(self, request, pk=None):
        serializer = FollowUpSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        service = LeadService(request.tenant, request.user)
        fup = service.add_followup(pk, serializer.validated_data)
        return ok(FollowUpSerializer(fup).data, "Follow-up added", status=201)


class QuotationViewSet(viewsets.GenericViewSet):
    serializer_class = QuotationListSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "quotations"
    search_fields = ["customer__full_name", "customer__mobile"]
    filterset_fields = ["status"]

    def get_queryset(self):
        tenant = self.request.tenant
        return Quotation.objects.filter(tenant=tenant, is_deleted=False).select_related("customer", "venue", "package", "lead").prefetch_related("items")

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return paginated(serializer.data, self.paginator)
        serializer = self.get_serializer(queryset, many=True)
        return ok(serializer.data)

    def retrieve(self, request, pk=None):
        quotation = get_object_or_404(Quotation.objects.select_related("customer", "venue", "lead").prefetch_related("items"), pk=pk, tenant=request.tenant)
        serializer = self.get_serializer(quotation)
        return ok(serializer.data)

    def create(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        quotation = serializer.save(tenant=request.tenant, created_by=request.user)
        return ok(QuotationDetailSerializer(quotation).data, "Quotation created", status=201)

    def update(self, request, pk=None):
        quotation = get_object_or_404(Quotation, pk=pk, tenant=request.tenant)
        serializer = self.get_serializer(quotation, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        quotation = serializer.save()
        return ok(QuotationDetailSerializer(quotation).data, "Quotation updated")

    def destroy(self, request, pk=None):
        quotation = get_object_or_404(Quotation, pk=pk, tenant=request.tenant)
        quotation.is_deleted = True
        quotation.save()
        return ok(None, "Quotation deleted")

    @action(detail=True, methods=["post"])
    def send(self, request, pk=None):
        quotation = get_object_or_404(Quotation, pk=pk, tenant=request.tenant)
        quotation.status = "SENT"
        quotation.save()
        return ok(QuotationDetailSerializer(quotation).data, "Quotation marked as sent")

    @action(detail=True, methods=["post"])
    def accept(self, request, pk=None):
        quotation = get_object_or_404(Quotation, pk=pk, tenant=request.tenant)
        service = QuotationService(request.tenant, request.user)
        try:
            booking = service.accept_quotation(pk)
            return ok({"quotation_id": quotation.id, "booking_id": booking.id}, "Quotation accepted, booking created")
        except ValidationException as e:
            return error(e.message)

    @action(detail=True, methods=["post"])
    def reject(self, request, pk=None):
        quotation = get_object_or_404(Quotation, pk=pk, tenant=request.tenant)
        quotation.status = "REJECTED"
        quotation.save()
        return ok(None, "Quotation rejected")
