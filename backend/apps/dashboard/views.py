from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from services.dashboard_service import DashboardService
from core.responses import ok
from permissions.module_access import ModuleAccessPermission


class DashboardSummaryView(APIView):
    permission_classes = [IsAuthenticated, ModuleAccessPermission]
    module_name = "dashboard"

    def get(self, request):
        tenant = request.tenant
        service = DashboardService(tenant, request.user)
        summary = service.get_summary()
        return ok(summary)
