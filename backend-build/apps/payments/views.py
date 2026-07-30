import json
import logging
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from django.db.models import Sum
from django.http import FileResponse, HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from apps.payments.models import Payment
from apps.payments.serializers import PaymentSerializer
from services.payment_service import PaymentService
from core.responses import ok, error
from core.exceptions import ValidationException

logger = logging.getLogger(__name__)

class PaymentViewSet(viewsets.ModelViewSet):
    serializer_class = PaymentSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "payments"
    filterset_fields = ["booking", "payment_method", "payment_type"]

    def get_queryset(self):
        tenant = self.request.tenant
        return Payment.objects.filter(tenant=tenant).select_related("booking__customer")

    def perform_create(self, serializer):
        service = PaymentService(self.request.tenant, self.request.user)
        data = serializer.validated_data.copy()
        booking = data.pop("booking")
        data["booking_id"] = booking.id if hasattr(booking, "id") else booking
        return service.create_payment(data)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            payment = self.perform_create(serializer)
            result = self.get_serializer(payment).data
            return ok(result, "Payment recorded", status=201)
        except ValidationException as e:
            return error(e.message)

    @action(detail=True, methods=["post"])
    def refund(self, request, pk=None):
        service = PaymentService(request.tenant, request.user)
        try:
            refund = service.refund_payment(pk)
            return ok(self.get_serializer(refund).data, "Payment refunded")
        except ValidationException as e:
            return error(e.message)

    @action(detail=True, methods=["get"])
    def receipt(self, request, pk=None):
        payment = self.get_object()
        return ok(PaymentSerializer(payment).data)

    @action(detail=True, methods=["get"])
    def outstanding(self, request, pk=None):
        service = PaymentService(request.tenant, request.user)
        data = service.get_outstanding(pk)
        return ok(data)

    @action(detail=True, methods=["get"])
    def receipt_pdf(self, request, pk=None):
        payment = self.get_object()
        service = PaymentService(request.tenant, request.user)
        pdf_content = service.generate_receipt_pdf(payment)
        return FileResponse(pdf_content, as_attachment=True, filename=f"receipt_{payment.id}.pdf")

    @action(detail=False, methods=["get"])
    def summary(self, request):
        service = PaymentService(request.tenant, request.user)
        data = service.get_payment_summary(
            request.query_params.get("start_date"),
            request.query_params.get("end_date"),
        )
        return ok(data)

    @action(detail=False, methods=["post"])
    def create_order(self, request):
        service = PaymentService(request.tenant, request.user)
        try:
            order = service.create_razorpay_order(
                booking_id=request.data.get("booking_id"),
                amount=request.data.get("amount"),
            )
            return ok(order, "Order created")
        except ValidationException as e:
            return error(e.message)

    @action(detail=False, methods=["post"])
    def verify(self, request):
        service = PaymentService(request.tenant, request.user)
        try:
            result = service.verify_razorpay_payment(
                order_id=request.data.get("razorpay_order_id"),
                payment_id=request.data.get("razorpay_payment_id"),
                signature=request.data.get("razorpay_signature"),
                booking_id=request.data.get("booking_id"),
            )
            return ok(result, "Payment verified")
        except ValidationException as e:
            return error(e.message)
