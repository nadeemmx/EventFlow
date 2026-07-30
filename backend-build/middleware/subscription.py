from django.utils.deprecation import MiddlewareMixin
from django.http import JsonResponse
from core.choices import UserRole, SubscriptionStatus


EXEMPT_PATHS = [
    "/api/v1/auth/",
    "/api/v1/profile/",
    "/api/v1/subscriptions/",
    "/admin/",
]


class SubscriptionGateMiddleware(MiddlewareMixin):
    def process_request(self, request):
        if not request.user or not request.user.is_authenticated:
            return None
        if request.user.role == UserRole.SUPER_ADMIN:
            return None
        path = request.path
        if any(path.startswith(p) for p in EXEMPT_PATHS):
            return None
        tenant = getattr(request, "tenant", None)
        if not tenant:
            return None
        if tenant.subscription_status in [
            SubscriptionStatus.EXPIRED, SubscriptionStatus.SUSPENDED
        ]:
            return JsonResponse(
                {
                    "success": False,
                    "message": "Your subscription has expired. Please renew to continue.",
                    "errors": {},
                },
                status=403,
            )
        return None
