from rest_framework.routers import DefaultRouter
from apps.authentication.views import (
    LoginView, RefreshView, LogoutView, ForgotPasswordView,
    ResetPasswordView, ChangePasswordView, ProfileView,
)
from apps.tenants.views import TenantViewSet
from apps.users.views import UserViewSet
from apps.customers.views import CustomerViewSet
from apps.leads.views import LeadViewSet
from apps.venues.views import VenueViewSet
from apps.packages.views import PackageViewSet
from apps.bookings.views import BookingViewSet
from apps.payments.views import PaymentViewSet
from apps.invoices.views import InvoiceViewSet
from apps.vendors.views import VendorViewSet
from apps.inventory.views import InventoryViewSet
from apps.staff.views import StaffViewSet
from apps.tasks.views import TaskViewSet
from apps.expenses.views import ExpenseViewSet
from apps.subscriptions.views import SubscriptionViewSet
from apps.notifications.views import NotificationViewSet
from apps.audit_logs.views import AuditLogViewSet
from apps.reports.views import ReportViewSet
from apps.dashboard.views import DashboardSummaryView
from apps.settings.views import SettingsViewSet
from apps.contracts.views import ContractViewSet
from apps.leads.views import QuotationViewSet
from django.views.decorators.csrf import csrf_exempt
from django.http import HttpResponse, JsonResponse
from django.urls import path
from gateway.payments.razorpay import RazorpayGateway
from apps.settings.models import PaymentGatewaySettings
import json
import logging

logger = logging.getLogger(__name__)


def razorpay_webhook(request):
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)
    try:
        body = request.body.decode("utf-8")
        signature = request.META.get("HTTP_X_RAZORPAY_SIGNATURE", "")
        settings = PaymentGatewaySettings.objects.filter(
            gateway="RAZORPAY", is_active=True, environment="live"
        ).first()
        if not settings:
            settings = PaymentGatewaySettings.objects.filter(
                gateway="RAZORPAY", is_active=True
            ).first()
        if not settings:
            logger.warning("Razorpay webhook: no active gateway settings found")
            return JsonResponse({"status": "ignored"})
        verified = RazorpayGateway.verify_webhook(body, signature, settings.webhook_secret)
        if not verified:
            logger.warning("Razorpay webhook signature verification failed")
            return JsonResponse({"error": "Invalid signature"}, status=400)
        data = json.loads(body)
        event = data.get("event", "")
        payload = data.get("payload", {})
        logger.info("Razorpay webhook event: %s", event)
        if event == "payment.captured":
            payment_entity = payload.get("payment", {}).get("entity", {})
            payment_id = payment_entity.get("id")
            order_id = payment_entity.get("order_id")
            amount = payment_entity.get("amount", 0)
            if payment_id and order_id:
                from apps.payments.models import Payment
                from core.choices import PaymentMethod
                existing = Payment.objects.filter(transaction_reference=payment_id).first()
                if not existing:
                    from apps.bookings.models import Booking
                    booking = Booking.objects.filter(
                        booking_number=order_id.split("_")[-1] if "_" in order_id else ""
                    ).first()
                    if not booking:
                        logger.warning("Razorpay webhook: no booking found for order %s", order_id)
                        return JsonResponse({"status": "ignored"})
                    Payment.objects.create(
                        tenant=booking.tenant,
                        booking=booking,
                        amount=amount / 100,
                        payment_method=PaymentMethod.RAZORPAY,
                        transaction_reference=payment_id,
                        payment_date=__import__("datetime").datetime.now().date(),
                    )
                    logger.info("Razorpay webhook: payment recorded for booking %s", booking.booking_number)
        return JsonResponse({"status": "ok"})
    except Exception as e:
        logger.error("Razorpay webhook error: %s", e)
        return JsonResponse({"error": str(e)}, status=500)



router = DefaultRouter()
router.register(r"tenants", TenantViewSet, basename="tenant")
router.register(r"users", UserViewSet, basename="user")
router.register(r"customers", CustomerViewSet, basename="customer")
router.register(r"leads", LeadViewSet, basename="lead")
router.register(r"venues", VenueViewSet, basename="venue")
router.register(r"packages", PackageViewSet, basename="package")
router.register(r"bookings", BookingViewSet, basename="booking")
router.register(r"payments", PaymentViewSet, basename="payment")
router.register(r"invoices", InvoiceViewSet, basename="invoice")
router.register(r"vendors", VendorViewSet, basename="vendor")
router.register(r"inventory", InventoryViewSet, basename="inventory")
router.register(r"staff", StaffViewSet, basename="staff")
router.register(r"tasks", TaskViewSet, basename="task")
router.register(r"expenses", ExpenseViewSet, basename="expense")
router.register(r"subscriptions", SubscriptionViewSet, basename="subscription")
router.register(r"notifications", NotificationViewSet, basename="notification")
router.register(r"audit-logs", AuditLogViewSet, basename="audit-log")
router.register(r"reports", ReportViewSet, basename="report")
router.register(r"settings", SettingsViewSet, basename="settings")
router.register(r"contracts", ContractViewSet, basename="contract")
router.register(r"quotations", QuotationViewSet, basename="quotation")

api_router = router

auth_urls = [
    path("auth/login/", LoginView.as_view(), name="auth-login"),
    path("auth/refresh/", RefreshView.as_view(), name="auth-refresh"),
    path("auth/logout/", LogoutView.as_view(), name="auth-logout"),
    path("auth/forgot-password/", ForgotPasswordView.as_view(), name="auth-forgot-password"),
    path("auth/reset-password/", ResetPasswordView.as_view(), name="auth-reset-password"),
    path("auth/change-password/", ChangePasswordView.as_view(), name="auth-change-password"),
    path("profile/", ProfileView.as_view(), name="profile"),
    path("dashboard/summary/", DashboardSummaryView.as_view(), name="dashboard-summary"),
    path("payments/webhook/razorpay/", csrf_exempt(razorpay_webhook), name="razorpay-webhook"),
]

api_router.urls.extend(auth_urls)
