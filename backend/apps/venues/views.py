from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from rest_framework.parsers import MultiPartParser, FormParser
from apps.venues.models import Venue
from apps.venues.serializers import VenueSerializer
from services.venue_service import VenueService
from core.responses import ok, error
from core.exceptions import ValidationException
class VenueViewSet(viewsets.ModelViewSet):
    serializer_class = VenueSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "venues"
    search_fields = ["name"]
    filterset_fields = ["status", "venue_type"]
    parser_classes = [MultiPartParser, FormParser]

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
