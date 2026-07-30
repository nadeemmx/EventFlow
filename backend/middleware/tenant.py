from django.utils.deprecation import MiddlewareMixin


class TenantMiddleware(MiddlewareMixin):
    def process_request(self, request):
        force_user = getattr(request, "_force_auth_user", None)
        if force_user is not None:
            request.tenant = getattr(force_user, "tenant", None)
        elif request.user and request.user.is_authenticated:
            request.tenant = request.user.tenant
        else:
            request.tenant = None
