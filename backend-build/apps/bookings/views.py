from django.db import models
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from apps.bookings.models import Booking
from apps.bookings.serializers import BookingSerializer, BookingHistorySerializer
from services.booking_service import BookingService
from core.responses import ok, error
from core.exceptions import ValidationException
class BookingViewSet(viewsets.ModelViewSet):
    serializer_class = BookingSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "bookings"
    search_fields = ["booking_number", "customer__full_name", "customer__mobile"]
    filterset_fields = ["status", "venue", "event_type"]

    def get_queryset(self):
        tenant = self.request.tenant
        return Booking.objects.filter(tenant=tenant, is_deleted=False).select_related(
            "customer", "venue", "package"
        )

    def perform_create(self, serializer):
        service = BookingService(self.request.tenant, self.request.user)
        booking = service.create_booking(serializer.validated_data)
        return booking

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            booking = self.perform_create(serializer)
            result = self.get_serializer(booking).data
            return ok(result, "Booking created", status=201)
        except ValidationException as e:
            return error(e.message)

    def perform_update(self, serializer):
        service = BookingService(self.request.tenant, self.request.user)
        service.repo.update(serializer.instance, **serializer.validated_data)

    @action(detail=True, methods=["post"])
    def confirm(self, request, pk=None):
        service = BookingService(request.tenant, request.user)
        try:
            booking = service.confirm_booking(pk)
            return ok(self.get_serializer(booking).data, "Booking confirmed")
        except ValidationException as e:
            return error(e.message)

    @action(detail=True, methods=["post"])
    def cancel(self, request, pk=None):
        service = BookingService(request.tenant, request.user)
        try:
            booking = service.cancel_booking(pk, request.data.get("remarks", ""))
            return ok(self.get_serializer(booking).data, "Booking cancelled")
        except ValidationException as e:
            return error(e.message)

    @action(detail=True, methods=["get"])
    def timeline(self, request, pk=None):
        service = BookingService(request.tenant, request.user)
        history = service.get_timeline(pk)
        serializer = BookingHistorySerializer(history, many=True)
        return ok(serializer.data)

    @action(detail=True, methods=["post"])
    def mark_in_progress(self, request, pk=None):
        service = BookingService(request.tenant, request.user)
        try:
            booking = service.mark_in_progress(pk)
            return ok(self.get_serializer(booking).data, "Booking marked in progress")
        except ValidationException as e:
            return error(e.message)

    @action(detail=True, methods=["post"])
    def mark_completed(self, request, pk=None):
        service = BookingService(request.tenant, request.user)
        try:
            booking = service.mark_completed(pk)
            return ok(self.get_serializer(booking).data, "Booking completed")
        except ValidationException as e:
            return error(e.message)

    @action(detail=False, methods=["get"])
    def calendar(self, request):
        month = request.query_params.get("month")
        year = request.query_params.get("year")
        venue_id = request.query_params.get("venue")
        if not all([month, year]):
            return error("month and year are required")
        service = BookingService(request.tenant, request.user)
        bookings = service.get_calendar(int(month), int(year), venue_id)
        serializer = self.get_serializer(bookings, many=True)
        return ok(serializer.data)

    @action(detail=True, methods=["get"])
    def outstanding(self, request, pk=None):
        from services.payment_service import PaymentService
        service = PaymentService(request.tenant, request.user)
        result = service.get_outstanding(pk)
        return ok(result)
