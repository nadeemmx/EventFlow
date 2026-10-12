import logging

from django.conf import settings
from django.core.mail import EmailMessage, send_mail
from django.utils import timezone
from rest_framework import mixins
from rest_framework.viewsets import GenericViewSet
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView
from decouple import config

from apps.privacy.models import ContactMessage, PrivacyRequest
from apps.privacy.serializers import (
    ContactRequestSerializer,
    PrivacyRequestAdminSerializer,
    PrivacyRequestCreateSerializer,
    PrivacyRequestUpdateSerializer,
)
from core.responses import ok
from core.utils import get_client_ip
from core.choices import UserRole
from permissions.module_access import ModuleAccessPermission

logger = logging.getLogger(__name__)

CONTACT_INBOX = config("CONTACT_INBOX_EMAIL", default="") or settings.DEFAULT_FROM_EMAIL
PRIVACY_INBOX = config("PRIVACY_INBOX_EMAIL", default="") or settings.DEFAULT_FROM_EMAIL


def _client_ip(request):
    ip = get_client_ip(request)
    return ip or None


class PrivacyRequestCreateView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "privacy_request"

    def post(self, request):
        serializer = PrivacyRequestCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        data.pop("privacy_acknowledged", None)

        instance = PrivacyRequest.objects.create(
            email=data["email"],
            full_name=data.get("full_name", ""),
            request_type=data["request_type"],
            description=data.get("description", ""),
            tenant=getattr(request, "tenant", None),
            user=request.user if request.user.is_authenticated else None,
            ip_address=_client_ip(request),
        )

        reference = f"PR-{instance.pk:06d}"
        subject = f"EventFlow privacy request received ({reference})"
        body = (
            f"We have received your privacy request.\n\n"
            f"Reference: {reference}\n"
            f"Type: {instance.get_request_type_display()}\n"
            f"Submitted: {instance.created_at:%Y-%m-%d %H:%M} UTC\n\n"
            f"We verify the requester before acting and aim to respond within 30 days. "
            f"Reply to this email if you have additional information to add.\n"
        )
        try:
            send_mail(
                subject,
                body,
                settings.DEFAULT_FROM_EMAIL,
                [instance.email],
                fail_silently=True,
            )
            send_mail(
                subject,
                (
                    f"New privacy request {reference}\n"
                    f"Type: {instance.get_request_type_display()}\n"
                    f"Email: {instance.email}\n"
                    f"Name: {instance.full_name or '-'}\n"
                    f"Tenant: {instance.tenant_id or '-'}\n\n"
                    f"Description:\n{instance.description or '-'}\n"
                ),
                settings.DEFAULT_FROM_EMAIL,
                [PRIVACY_INBOX],
                fail_silently=True,
            )
        except Exception:
            logger.exception("Failed to send privacy request notification emails")

        return ok(
            {"reference": reference, "status": instance.status},
            "Your request has been received. Keep the reference number for follow-up.",
            status=201,
        )


class PrivacyRequestViewSet(
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    mixins.UpdateModelMixin,
    GenericViewSet,
):
    """Owner / super-admin review of submitted privacy requests."""

    serializer_class = PrivacyRequestAdminSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission]
    module_name = "privacy"

    def get_queryset(self):
        queryset = PrivacyRequest.objects.all()
        if self.request.user.role != UserRole.SUPER_ADMIN:
            queryset = queryset.filter(tenant=self.request.tenant)
        return queryset.order_by("-created_at")

    def get_serializer_class(self):
        if self.request.method in ("PUT", "PATCH"):
            return PrivacyRequestUpdateSerializer
        return PrivacyRequestAdminSerializer

    def perform_update(self, serializer):
        instance = serializer.save()
        if instance.status in (
            PrivacyRequest.Status.ACTIONED,
            PrivacyRequest.Status.REJECTED,
            PrivacyRequest.Status.CLOSED,
        ) and instance.responded_at is None:
            instance.responded_at = timezone.now()
            instance.save(update_fields=["responded_at"])


class ContactView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "contact"

    def post(self, request):
        serializer = ContactRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        resume = data.get("resume")

        message = ContactMessage.objects.create(
            source=data["source"],
            name=data["name"],
            email=data["email"],
            company=data.get("company", ""),
            phone=data.get("phone", ""),
            subject=data.get("subject", ""),
            message=data["message"],
            privacy_acknowledged=data.get("privacy_acknowledged", False),
            marketing_opt_in=data.get("marketing_opt_in", False),
            resume=resume,
            ip_address=_client_ip(request),
        )

        body = (
            f"New {message.get_source_display()} submission\n"
            f"----------------------------------------\n"
            f"Name: {message.name}\n"
            f"Email: {message.email}\n"
            f"Company: {message.company or '-'}\n"
            f"Phone: {message.phone or '-'}\n"
            f"Subject: {message.subject or '-'}\n"
            f"Privacy notice acknowledged: {'yes' if message.privacy_acknowledged else 'no'}\n"
            f"Marketing email opt-in: {'yes' if message.marketing_opt_in else 'no'}\n"
            f"Resume attached: {'yes' if resume else 'no'}\n"
            f"Reference: CM-{message.pk:06d}\n"
            f"----------------------------------------\n\n"
            f"{message.message}\n"
        )
        try:
            mail = EmailMessage(
                f"EventFlow {message.get_source_display()} — {message.subject or message.name}",
                body,
                settings.DEFAULT_FROM_EMAIL,
                [CONTACT_INBOX],
            )
            if resume:
                resume.seek(0)
                mail.attach(resume.name, resume.read(), "application/pdf")
            mail.send(fail_silently=True)
            send_mail(
                "We received your message",
                (
                    f"Hi {message.name},\n\n"
                    "Thanks for getting in touch. Your reference is "
                    f"CM-{message.pk:06d} — keep it if you need to follow up.\n\n"
                    "If your message needs a reply, we will contact you at this address.\n"
                ),
                settings.DEFAULT_FROM_EMAIL,
                [message.email],
                fail_silently=True,
            )
        except Exception:
            logger.exception("Failed to send contact notification emails")

        return ok(
            {"reference": f"CM-{message.pk:06d}"},
            "Thanks — your message has been received.",
            status=201,
        )
