from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from services.dashboard_service import DashboardService
from core.responses import ok
from permissions.module_access import ModuleAccessPermission
from permissions.roles import IsSuperAdmin
from apps.tenants.models import Tenant
from apps.venues.models import Venue
from apps.bookings.models import Booking
from apps.payments.models import Payment
from core.choices import PaymentType
from django.db.models import Count, Sum
from django.utils import timezone
from datetime import timedelta


class DashboardSummaryView(APIView):
    permission_classes = [IsAuthenticated, ModuleAccessPermission]
    module_name = "dashboard"

    def get(self, request):
        tenant = request.tenant
        service = DashboardService(tenant, request.user)
        summary = service.get_summary()
        return ok(summary)


class PlatformAdminStatsView(APIView):
    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def get(self, request):
        now = timezone.now()
        start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

        total_tenants = Tenant.objects.count()
        active_tenants = Tenant.objects.filter(status="ACTIVE").count()

        total_venues = Venue.objects.count()
        active_venues = Venue.objects.filter(status="ACTIVE").count()

        bookings_this_month = Booking.objects.filter(created_at__gte=start_of_month).count()

        payments_this_month = Payment.objects.filter(
            created_at__gte=start_of_month,
            payment_type=PaymentType.PAYMENT
        ).aggregate(total=Sum("amount"))["total"] or 0
        refunds_this_month = Payment.objects.filter(
            created_at__gte=start_of_month,
            payment_type=PaymentType.REFUND
        ).aggregate(total=Sum("amount"))["total"] or 0
        revenue_this_month = payments_this_month - refunds_this_month

        pending_approvals = Tenant.objects.filter(status="TRIAL").count()

        return ok({
            "total_tenants": total_tenants,
            "active_tenants": active_tenants,
            "total_venues": total_venues,
            "active_venues": active_venues,
            "total_bookings_this_month": bookings_this_month,
            "total_revenue_this_month": float(revenue_this_month),
            "pending_approvals": pending_approvals,
        })
