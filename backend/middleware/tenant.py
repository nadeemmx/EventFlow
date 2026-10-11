from django.utils.deprecation import MiddlewareMixin


class TenantMiddleware(MiddlewareMixin):
    """Attach the tenant for the current request to ``request.tenant``.

    This only covers the simple case: the authenticated user's own tenant.
    JWT auth runs *inside* DRF view dispatch (after middleware), so
    ``TenantJWTAuthentication`` is the authority for ``request.tenant`` on
    API requests and overrides whatever is set here — it is also the only
    place that can honour SUPER_ADMIN's explicitly-supplied tenant. See
    ``core/tenant_resolution.py``.
    """

    def process_request(self, request):
        force_user = getattr(request, "_force_auth_user", None)
        if force_user is not None:
            user = force_user
        elif request.user and request.user.is_authenticated:
            user = request.user
        else:
            request.tenant = None
            return
        request.tenant = getattr(user, "tenant", None)
