from django.db import models
from django.db.models import Sum, Count, Q
from django.db.models.functions import TruncMonth
from repositories.booking_repository import BookingRepository
from repositories.payment_repository import PaymentRepository
from repositories.lead_repository import LeadRepository
from repositories.customer_repository import CustomerRepository
from repositories.vendor_repository import VendorRepository
from repositories.inventory_repository import InventoryRepository
from services.base import BaseService
from core.choices import BookingStatus, PaymentType, LeadStatus
from core.cache import CacheService, build_cache_key
from datetime import datetime, timedelta
import csv
from io import StringIO
from django.http import HttpResponse


class ReportService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.booking_repo = BookingRepository(self.tenant, self.user)
        self.payment_repo = PaymentRepository(self.tenant, self.user)
        self.lead_repo = LeadRepository(self.tenant, self.user)

    def get_date_filtered_bookings(self, start_date=None, end_date=None):
        qs = self.booking_repo.get_queryset()
        if start_date:
            qs = qs.filter(event_date__gte=start_date)
        if end_date:
            qs = qs.filter(event_date__lte=end_date)
        return qs

    def get_date_filtered_payments(self, start_date=None, end_date=None):
        qs = self.payment_repo.get_queryset()
        if start_date:
            qs = qs.filter(payment_date__gte=start_date)
        if end_date:
            qs = qs.filter(payment_date__lte=end_date)
        return qs

    def revenue_report(self, start_date=None, end_date=None):
        if self.tenant:
            cache_key = build_cache_key("report", "revenue", start_date, end_date, self.tenant.id)
            return CacheService.get_or_set(cache_key, lambda: self._revenue_report(start_date, end_date), CacheService.REPORT_TTL)
        return self._revenue_report(start_date, end_date)

    def _revenue_report(self, start_date=None, end_date=None):
        payment_qs = self.get_date_filtered_payments(start_date, end_date)
        booking_qs = self.get_date_filtered_bookings(start_date, end_date)
        
        payments = payment_qs.filter(payment_type=PaymentType.PAYMENT)
        refunds = payment_qs.filter(payment_type=PaymentType.REFUND)
        
        total_revenue = payments.aggregate(total=Sum("amount"))["total"] or 0
        total_refunds = refunds.aggregate(total=Sum("amount"))["total"] or 0
        total_bookings = booking_qs.count()
        avg_value = 0
        if total_bookings > 0:
            avg_value = booking_qs.aggregate(avg=Sum("total_amount") / Count("id"))["avg"] or 0
        
        return {
            "total_revenue": float(total_revenue),
            "total_refunds": float(total_refunds),
            "net_revenue": float(total_revenue - total_refunds),
            "total_bookings": total_bookings,
            "average_booking_value": float(avg_value),
        }

    def booking_report(self, start_date=None, end_date=None):
        if self.tenant:
            cache_key = build_cache_key("report", "booking", start_date, end_date, self.tenant.id)
            return CacheService.get_or_set(cache_key, lambda: self._booking_report(start_date, end_date), CacheService.REPORT_TTL)
        return self._booking_report(start_date, end_date)

    def _booking_report(self, start_date=None, end_date=None):
        qs = self.get_date_filtered_bookings(start_date, end_date)
        total = qs.count()
        by_status = dict(qs.values_list("status").annotate(count=Count("id")))
        by_event_type = dict(qs.values_list("event_type").annotate(count=Count("id")))
        total_count = qs.count()
        avg_value = 0
        if total_count > 0:
            avg_value = qs.aggregate(avg=Sum("total_amount") / Count("id"))["avg"] or 0
        
        return {
            "total_bookings": total,
            "by_status": by_status,
            "by_event_type": by_event_type,
            "average_booking_value": float(avg_value),
        }

    def payment_report(self, start_date=None, end_date=None):
        if self.tenant:
            cache_key = build_cache_key("report", "payment", start_date, end_date, self.tenant.id)
            return CacheService.get_or_set(cache_key, lambda: self._payment_report(start_date, end_date), CacheService.REPORT_TTL)
        return self._payment_report(start_date, end_date)

    def _payment_report(self, start_date=None, end_date=None):
        qs = self.get_date_filtered_payments(start_date, end_date)
        payments = qs.filter(payment_type=PaymentType.PAYMENT)
        refunds = qs.filter(payment_type=PaymentType.REFUND)
        
        total_collected = payments.aggregate(total=Sum("amount"))["total"] or 0
        total_refunded = refunds.aggregate(total=Sum("amount"))["total"] or 0
        by_method = dict(payments.values_list("payment_method").annotate(total=Sum("amount")))
        
        return {
            "total_collected": float(total_collected),
            "total_refunded": float(total_refunded),
            "net_revenue": float(total_collected - total_refunded),
            "by_method": {k: float(v) for k, v in by_method.items()},
        }

    def occupancy_report(self, venue_id=None):
        if self.tenant:
            cache_key = build_cache_key("report", "occupancy", venue_id, self.tenant.id)
            return CacheService.get_or_set(cache_key, lambda: self._occupancy_report(venue_id), CacheService.REPORT_TTL)
        return self._occupancy_report(venue_id)

    def _occupancy_report(self, venue_id=None):
        from apps.venues.models import Venue
        venues = Venue.objects.filter(tenant=self.tenant, is_deleted=False)
        if venue_id:
            venues = venues.filter(id=venue_id)
        report = []
        for venue in venues:
            total_days = 365
            booked_days = self.booking_repo.get_queryset().filter(
                venue=venue,
                status__in=[BookingStatus.CONFIRMED, BookingStatus.COMPLETED, BookingStatus.TENTATIVE],
            ).count()
            occupancy_pct = round((booked_days / total_days) * 100, 2) if total_days else 0
            report.append({
                "venue_id": venue.id,
                "venue_name": venue.name,
                "total_capacity": venue.capacity,
                "bookings_count": booked_days,
                "occupancy_percentage": occupancy_pct,
            })
        return report

    def lead_report(self, start_date=None, end_date=None):
        if self.tenant:
            cache_key = build_cache_key("report", "lead", start_date, end_date, self.tenant.id)
            return CacheService.get_or_set(cache_key, lambda: self._lead_report(start_date, end_date), CacheService.REPORT_TTL)
        return self._lead_report(start_date, end_date)

    def _lead_report(self, start_date=None, end_date=None):
        qs = self.lead_repo.get_queryset()
        if start_date:
            qs = qs.filter(created_at__gte=start_date)
        if end_date:
            qs = qs.filter(created_at__lte=end_date)
        
        total = qs.count()
        by_status = dict(qs.values_list("lead_status").annotate(count=Count("id")))
        by_source = dict(qs.values_list("lead_source").annotate(count=Count("id")))
        converted = qs.filter(lead_status=LeadStatus.CONVERTED).count()
        lost = qs.filter(lead_status=LeadStatus.LOST).count()
        active = qs.filter(lead_status__in=[LeadStatus.NEW, LeadStatus.CONTACTED, LeadStatus.SITE_VISIT, LeadStatus.NEGOTIATION, LeadStatus.QUOTATION_SENT, LeadStatus.ADVANCE_RECEIVED]).count()
        conversion_rate = round((converted / total * 100), 2) if total > 0 else 0
        
        return {
            "total_leads": total,
            "by_status": by_status,
            "by_source": by_source,
            "conversion_rate": conversion_rate,
            "converted": converted,
            "lost": lost,
            "active": active,
        }

    def vendor_report(self):
        if self.tenant:
            cache_key = build_cache_key("report", "vendor", self.tenant.id)
            return CacheService.get_or_set(cache_key, self._vendor_report, CacheService.REPORT_TTL)
        return self._vendor_report()

    def _vendor_report(self):
        from apps.vendors.models import Vendor
        qs = Vendor.objects.filter(tenant=self.tenant, is_deleted=False)
        total = qs.count()
        active = qs.filter(status="ACTIVE").count()
        by_type = dict(qs.values_list("vendor_type").annotate(count=Count("id")))
        return {
            "total_vendors": total,
            "active_vendors": active,
            "by_type": by_type,
        }

    def inventory_report(self):
        if self.tenant:
            cache_key = build_cache_key("report", "inventory", self.tenant.id)
            return CacheService.get_or_set(cache_key, self._inventory_report, CacheService.REPORT_TTL)
        return self._inventory_report()

    def _inventory_report(self):
        from apps.inventory.models import InventoryItem
        qs = InventoryItem.objects.filter(tenant=self.tenant, is_deleted=False)
        total = qs.count()
        low_stock = qs.filter(
            Q(available_quantity__lte=models.F("total_quantity") * 0.2) | Q(available_quantity__lte=5)
        ).count()
        by_category = dict(qs.values_list("category").annotate(count=Count("id")))
        return {
            "total_items": total,
            "low_stock_items": low_stock,
            "by_category": by_category,
        }

    def outstanding_payments_report(self):
        if self.tenant:
            cache_key = build_cache_key("report", "outstanding", self.tenant.id)
            return CacheService.get_or_set(cache_key, self._outstanding_payments_report, CacheService.REPORT_TTL)
        return self._outstanding_payments_report()

    def _outstanding_payments_report(self):
        bookings = self.booking_repo.get_queryset().filter(
            status__in=[BookingStatus.CONFIRMED, BookingStatus.TENTATIVE, BookingStatus.IN_PROGRESS],
        ).select_related("customer", "venue")
        report = []
        for booking in bookings:
            total_paid = self.payment_repo.get_total_paid(booking)
            outstanding = booking.total_amount - total_paid
            if outstanding > 0:
                report.append({
                    "booking_id": booking.id,
                    "booking_number": booking.booking_number,
                    "customer_name": booking.customer.full_name if booking.customer else "",
                    "venue_name": booking.venue.name if booking.venue else "",
                    "event_date": str(booking.event_date),
                    "total_amount": float(booking.total_amount),
                    "total_paid": float(total_paid),
                    "outstanding": float(outstanding),
                    "payment_status": "PARTIAL" if total_paid > 0 else "PENDING",
                })
        return report

    def monthly_growth_report(self, year=None):
        if self.tenant:
            cache_key = build_cache_key("report", "monthly_growth", year, self.tenant.id)
            return CacheService.get_or_set(cache_key, lambda: self._monthly_growth_report(year), CacheService.REPORT_TTL)
        return self._monthly_growth_report(year)

    def _monthly_growth_report(self, year=None):
        if not year:
            year = datetime.now().year
        bookings = self.booking_repo.get_queryset().filter(event_date__year=year)
        payments = self.payment_repo.get_queryset().filter(payment_date__year=year, payment_type=PaymentType.PAYMENT)
        leads = self.lead_repo.get_queryset().filter(created_at__year=year)
        
        booking_monthly = bookings.annotate(month=TruncMonth("event_date")).values("month").annotate(count=Count("id")).order_by("month")
        payment_monthly = payments.annotate(month=TruncMonth("payment_date")).values("month").annotate(total=Sum("amount")).order_by("month")
        lead_monthly = leads.annotate(month=TruncMonth("created_at")).values("month").annotate(count=Count("id")).order_by("month")
        
        booking_data = {str(b["month"]): b["count"] for b in booking_monthly if b["month"]}
        payment_data = {str(p["month"]): float(p["total"]) for p in payment_monthly if p["month"]}
        lead_data = {str(l["month"]): l["count"] for l in lead_monthly if l["month"]}
        
        all_months = sorted(set(list(booking_data.keys()) + list(payment_data.keys()) + list(lead_data.keys())))
        
        report = []
        for month_str in all_months:
            dt = datetime.strptime(month_str.split(" ")[0] if " " in month_str else month_str[:10], "%Y-%m-%d")
            report.append({
                "month": dt.strftime("%B"),
                "year": dt.year,
                "revenue": payment_data.get(month_str, 0),
                "booking_count": booking_data.get(month_str, 0),
                "new_leads": lead_data.get(month_str, 0),
                "conversion_count": 0,
            })
        return report

    def export_csv(self, data, filename="report"):
        if isinstance(data, dict):
            data = [data]
        keys = data[0].keys() if data else []
        output = StringIO()
        writer = csv.DictWriter(output, fieldnames=keys)
        writer.writeheader()
        for row in data:
            flat_row = {}
            for k, v in row.items():
                if isinstance(v, dict):
                    for sub_k, sub_v in v.items():
                        flat_row[f"{k}_{sub_k}"] = sub_v
                else:
                    flat_row[k] = v
            writer.writerow(flat_row)
        response = HttpResponse(output.getvalue(), content_type="text/csv")
        response["Content-Disposition"] = f"attachment; filename={filename}.csv"
        return response
