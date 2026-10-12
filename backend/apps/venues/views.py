from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from apps.venues.models import Venue
from apps.venues.serializers import PlatformAdminVenueSerializer, VenueSerializer
from services.venue_service import VenueService
from core.responses import ok, error
from core.exceptions import ValidationException
from permissions.roles import IsSuperAdmin
from core.choices import VenueStatus


class VenueViewSet(viewsets.ModelViewSet):
    serializer_class = VenueSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "venues"
    search_fields = ["name"]
    filterset_fields = ["status", "venue_type"]
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def get_queryset(self):
        tenant = self.request.tenant
        return Venue.objects.filter(tenant=tenant, is_deleted=False).prefetch_related("images")

    def perform_create(self, serializer):
        serializer.save(tenant=self.request.tenant, created_by=self.request.user)

    def perform_destroy(self, instance):
        from apps.bookings.models import Booking
        if Booking.objects.filter(venue=instance).exists():
            raise ValidationException("Cannot delete venue with booking history")
        instance.is_deleted = True
        instance.deleted_by = self.request.user
        instance.save()

    @action(detail=True, methods=["post"], parser_classes=[MultiPartParser, FormParser])
    def images(self, request, pk=None):
        service = VenueService(request.tenant, request.user)
        try:
            image = service.add_image(pk, request.FILES.get("image"))
            from apps.venues.serializers import VenueImageSerializer
            return ok(VenueImageSerializer(image).data, "Image uploaded", status=201)
        except ValidationException as e:
            return error(e.message)


class PlatformAdminVenueViewSet(viewsets.GenericViewSet):
    """Platform Admin only - manage all venues across all tenants"""
    serializer_class = PlatformAdminVenueSerializer
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    search_fields = ["name", "tenant__business_name"]
    filterset_fields = ["status", "venue_type", "tenant"]
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def get_queryset(self):
        return Venue.objects.all().select_related("tenant").prefetch_related("images")

    def list(self, request):
        venues = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(venues)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(venues, many=True)
        return ok(serializer.data)

    def retrieve(self, request, pk=None):
        venue = self.get_object()
        serializer = self.get_serializer(venue)
        return ok(serializer.data)

    @action(detail=True, methods=["post"])
    def activate(self, request, pk=None):
        venue = self.get_object()
        venue.status = VenueStatus.ACTIVE
        venue.save(update_fields=["status", "updated_at"])
        return ok(self.get_serializer(venue).data, "Venue activated")

    @action(detail=True, methods=["post"])
    def suspend(self, request, pk=None):
        venue = self.get_object()
        venue.status = VenueStatus.MAINTENANCE
        venue.save(update_fields=["status", "updated_at"])
        return ok(self.get_serializer(venue).data, "Venue suspended")

    @action(detail=True, methods=["post"])
    def disable(self, request, pk=None):
        venue = self.get_object()
        venue.status = VenueStatus.INACTIVE
        venue.save(update_fields=["status", "updated_at"])
        return ok(self.get_serializer(venue).data, "Venue disabled")
