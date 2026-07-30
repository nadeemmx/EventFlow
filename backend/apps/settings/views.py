from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from apps.settings.serializers import (
    PaymentGatewaySettingsSerializer, WhatsAppSettingsSerializer,
    EmailSettingsSerializer, InvoiceSettingsSerializer,
    BookingSettingsSerializer, NotificationSettingsSerializer,
    SecuritySettingsSerializer, BrandingSettingsSerializer,
    OrganizationSettingsSerializer, ProfileSerializer,
    UserSerializer, RoleSerializer, SettingsSubscriptionSerializer,
)
from apps.settings.services import SettingsService
from core.responses import ok, error, paginated
from core.exceptions import ValidationException, ConflictException


class SettingsViewSet(viewsets.GenericViewSet):
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "settings"

    @property
    def service(self):
        return SettingsService(self.request.tenant, self.request.user)

    @action(detail=False, methods=["get", "put"])
    def payment_gateway(self, request):
        if request.method == "GET":
            instance = self.service.get_payment_gateway_settings()
            return ok(PaymentGatewaySettingsSerializer(instance).data)
        try:
            instance = self.service.update_payment_gateway_settings(request.data)
            return ok(PaymentGatewaySettingsSerializer(instance).data)
        except ValidationException as e:
            return error(e.message)

    @action(detail=False, methods=["get", "put"])
    def whatsapp(self, request):
        if request.method == "GET":
            instance = self.service.get_whatsapp_settings()
            return ok(WhatsAppSettingsSerializer(instance).data)
        try:
            instance = self.service.update_whatsapp_settings(request.data)
            return ok(WhatsAppSettingsSerializer(instance).data)
        except ValidationException as e:
            return error(e.message)

    @action(detail=False, methods=["get", "put"])
    def email(self, request):
        if request.method == "GET":
            instance = self.service.get_email_settings()
            return ok(EmailSettingsSerializer(instance).data)
        try:
            instance = self.service.update_email_settings(request.data)
            return ok(EmailSettingsSerializer(instance).data)
        except ValidationException as e:
            return error(e.message)

    @action(detail=False, methods=["get", "put"])
    def invoice(self, request):
        if request.method == "GET":
            instance = self.service.get_invoice_settings()
            return ok(InvoiceSettingsSerializer(instance).data)
        try:
            instance = self.service.update_invoice_settings(request.data)
            return ok(InvoiceSettingsSerializer(instance).data)
        except ValidationException as e:
            return error(e.message)

    @action(detail=False, methods=["get", "put"])
    def booking(self, request):
        if request.method == "GET":
            instance = self.service.get_booking_settings()
            return ok(BookingSettingsSerializer(instance).data)
        try:
            instance = self.service.update_booking_settings(request.data)
            return ok(BookingSettingsSerializer(instance).data)
        except ValidationException as e:
            return error(e.message)

    @action(detail=False, methods=["get", "put"], url_path="notifications")
    def notifications(self, request):
        if request.method == "GET":
            instance = self.service.get_notification_settings()
            return ok(NotificationSettingsSerializer(instance).data)
        try:
            instance = self.service.update_notification_settings(request.data)
            return ok(NotificationSettingsSerializer(instance).data)
        except ValidationException as e:
            return error(e.message)

    @action(detail=False, methods=["get", "put"])
    def security(self, request):
        if request.method == "GET":
            instance = self.service.get_security_settings()
            return ok(SecuritySettingsSerializer(instance).data)
        try:
            instance = self.service.update_security_settings(request.data)
            return ok(SecuritySettingsSerializer(instance).data)
        except ValidationException as e:
            return error(e.message)

    @action(detail=False, methods=["get", "put"])
    def branding(self, request):
        if request.method == "GET":
            instance = self.service.get_branding_settings()
            return ok(BrandingSettingsSerializer(instance).data)
        try:
            instance = self.service.update_branding_settings(request.data)
            return ok(BrandingSettingsSerializer(instance).data)
        except ValidationException as e:
            return error(e.message)

    @action(detail=False, methods=["get", "put"])
    def organization(self, request):
        if request.method == "GET":
            return ok(OrganizationSettingsSerializer(self.service.get_organization_settings()).data)
        try:
            instance = self.service.update_organization_settings(request.data)
            return ok(OrganizationSettingsSerializer(instance).data)
        except ValidationException as e:
            return error(e.message)

    @action(detail=False, methods=["get", "put"])
    def profile(self, request):
        if request.method == "GET":
            return ok(ProfileSerializer(self.service.get_profile()).data)
        try:
            instance = self.service.update_profile(request.data)
            return ok(ProfileSerializer(instance).data)
        except ValidationException as e:
            return error(e.message)

    @action(detail=False, methods=["get", "post"])
    def users(self, request):
        if request.method == "GET":
            page = int(request.query_params.get("page", 1))
            page_size = int(request.query_params.get("page_size", 20))
            page_obj = self.service.get_user_list(page=page, page_size=page_size)
            serializer = UserSerializer(page_obj.object_list, many=True)
            return ok({
                "results": serializer.data,
                "page": page_obj.number,
                "page_size": page_obj.paginator.per_page,
                "total_records": page_obj.paginator.count,
                "total_pages": page_obj.paginator.num_pages,
            })
        try:
            user = self.service.create_user(request.data)
            return ok(UserSerializer(user).data, "User created", status=201)
        except (ValidationException, ConflictException) as e:
            return error(e.message)

    @action(detail=True, methods=["put"])
    def update_user(self, request, pk=None):
        try:
            user = self.service.update_user(pk, request.data)
            return ok(UserSerializer(user).data)
        except ValidationException as e:
            return error(e.message)

    @action(detail=True, methods=["delete"])
    def delete_user(self, request, pk=None):
        try:
            self.service.delete_user(pk)
            return ok(None, "User deleted")
        except ValidationException as e:
            return error(e.message)

    @action(detail=True, methods=["post"], url_path="activate")
    def activate_user(self, request, pk=None):
        user = self.service.activate_user(pk)
        return ok(UserSerializer(user).data, "User activated")

    @action(detail=True, methods=["post"], url_path="deactivate")
    def deactivate_user(self, request, pk=None):
        try:
            user = self.service.deactivate_user(pk)
            return ok(UserSerializer(user).data, "User deactivated")
        except ValidationException as e:
            return error(e.message)

    @action(detail=False, methods=["get"])
    def roles(self, request):
        roles = self.service.get_role_choices()
        return ok(RoleSerializer(roles, many=True).data)

    @action(detail=False, methods=["get"])
    def subscription(self, request):
        sub = self.service.get_current_subscription()
        if sub:
            return ok(sub)
        return ok(None, "No active subscription")
