from django.utils import timezone
from django.db.models import Sum, Count, Q
from datetime import timedelta
from repositories.booking_repository import BookingRepository
from repositories.payment_repository import PaymentRepository
from repositories.lead_repository import LeadRepository
from core.choices import BookingStatus, PaymentType, LeadStatus
from core.cache import CacheService, build_cache_key


class DashboardService:
    def __init__(self, tenant=None, user=None):
        self.tenant = tenant
        self.user = user
        self.booking_repo = BookingRepository(self.tenant, self.user)
        self.payment_repo = PaymentRepository(self.tenant, self.user)
        self.lead_repo = LeadRepository(self.tenant, self.user)

    def get_summary(self):
        if not self.tenant:
            return self._compute_summary()
        cache_key = build_cache_key("dashboard", "summary", self.tenant.id)
        return CacheService.get_or_set(cache_key, self._compute_summary, CacheService.DASHBOARD_TTL)

    def _compute_summary(self):
        today = timezone.now().date()
        start_of_month = today.replace(day=1)

        bookings_qs = self.booking_repo.get_queryset()
        payments_qs = self.payment_repo.get_queryset()
        leads_qs = self.lead_repo.get_queryset()

        today_events = bookings_qs.filter(event_date=today, status__in=[
            BookingStatus.CONFIRMED, BookingStatus.IN_PROGRESS
        ]).count()

        upcoming_bookings = bookings_qs.filter(
            event_date__gte=today,
            status__in=[BookingStatus.CONFIRMED, BookingStatus.TENTATIVE]
        ).count()

        active_leads = leads_qs.filter(
            lead_status__in=[LeadStatus.NEW, LeadStatus.CONTACTED,
                             LeadStatus.SITE_VISIT, LeadStatus.NEGOTIATION,
                             LeadStatus.QUOTATION_SENT, LeadStatus.ADVANCE_RECEIVED]
        ).count()

        monthly_payments = payments_qs.filter(
            payment_date__gte=start_of_month,
            payment_date__lte=today,
            payment_type=PaymentType.PAYMENT,
        )
        monthly_revenue = monthly_payments.aggregate(
            total=Sum("amount")
        )["total"] or 0

        pending_payments = 0
        for booking in bookings_qs.filter(
            status__in=[BookingStatus.CONFIRMED, BookingStatus.IN_PROGRESS, BookingStatus.TENTATIVE],
        ):
            total_paid = self.payment_repo.get_total_paid(booking)
            if total_paid < booking.total_amount:
                pending_payments += 1

        return {
            "today_events": today_events,
            "upcoming_bookings": upcoming_bookings,
            "pending_payments": pending_payments,
            "active_leads": active_leads,
            "monthly_revenue": float(monthly_revenue),
        }
