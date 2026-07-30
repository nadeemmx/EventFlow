from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from django.http import HttpResponse
from services.report_service import ReportService
from core.responses import ok

class ReportViewSet(viewsets.GenericViewSet):
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "reports"

    def get_report_service(self):
        return ReportService(self.request.tenant, self.request.user)

    @action(detail=False, methods=["get"])
    def revenue(self, request):
        service = self.get_report_service()
        data = service.revenue_report(
            request.query_params.get("start_date"),
            request.query_params.get("end_date"),
        )
        format = request.query_params.get("format")
        if format == "csv":
            return service.export_csv(data, "revenue_report")
        return ok(data)

    @action(detail=False, methods=["get"])
    def bookings(self, request):
        service = self.get_report_service()
        data = service.booking_report(
            request.query_params.get("start_date"),
            request.query_params.get("end_date"),
        )
        format = request.query_params.get("format")
        if format == "csv":
            return service.export_csv(data, "booking_report")
        return ok(data)

    @action(detail=False, methods=["get"])
    def payments(self, request):
        service = self.get_report_service()
        data = service.payment_report(
            request.query_params.get("start_date"),
            request.query_params.get("end_date"),
        )
        return ok(data)

    @action(detail=False, methods=["get"])
    def occupancy(self, request):
        service = self.get_report_service()
        data = service.occupancy_report(
            request.query_params.get("venue"),
        )
        return ok(data)

    @action(detail=False, methods=["get"])
    def leads(self, request):
        service = self.get_report_service()
        data = service.lead_report(
            request.query_params.get("start_date"),
            request.query_params.get("end_date"),
        )
        format = request.query_params.get("format")
        if format == "csv":
            return service.export_csv(data, "leads_report")
        return ok(data)

    @action(detail=False, methods=["get"])
    def vendors(self, request):
        service = self.get_report_service()
        data = service.vendor_report()
        return ok(data)

    @action(detail=False, methods=["get"])
    def inventory(self, request):
        service = self.get_report_service()
        data = service.inventory_report()
        return ok(data)

    @action(detail=False, methods=["get"])
    def outstanding(self, request):
        service = self.get_report_service()
        data = service.outstanding_payments_report()
        format = request.query_params.get("format")
        if format == "csv":
            return service.export_csv(data, "outstanding_payments")
        return ok(data)

    @action(detail=False, methods=["get"])
    def monthly_growth(self, request):
        service = self.get_report_service()
        data = service.monthly_growth_report(
            request.query_params.get("year"),
        )
        format = request.query_params.get("format")
        if format == "csv":
            return service.export_csv(data, "monthly_growth")
        return ok(data)

    @action(detail=False, methods=["get"])
    def export(self, request):
        report_type = request.query_params.get("type", "revenue")
        fmt = request.query_params.get("format", "csv")
        service = self.get_report_service()
        if report_type == "revenue":
            data = service.revenue_report(request.query_params.get("start_date"), request.query_params.get("end_date"))
            data_list = [data]
        elif report_type == "bookings":
            data = service.booking_report(request.query_params.get("start_date"), request.query_params.get("end_date"))
            data_list = [data]
        elif report_type == "outstanding":
            data = service.outstanding_payments_report()
            data_list = data
        else:
            return ok({"error": "Unknown report type"})
        filename = f"{report_type}_report"
        if fmt == "csv":
            return service.export_csv(data_list if isinstance(data_list, list) else [data_list], filename)
        return ok(data)
