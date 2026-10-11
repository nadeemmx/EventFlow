from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError

from core.tenant_resolution import resolve_tenant_for_request
from core.tokens import BlacklistCheckingAccessToken


class TenantJWTAuthentication(JWTAuthentication):
    def get_validated_token(self, raw_token):
        """Validate with the blacklist-aware access token.

        simplejwt hardcodes ``AccessToken`` here and that class does not check
        the blacklist, so a token revoked by logout would still authenticate.
        Substituting our subclass makes revocation fail closed at the same
        point an expired token fails, with the usual 401.
        """
        try:
            return BlacklistCheckingAccessToken(raw_token)
        except TokenError as exc:
            raise InvalidToken(str(exc))

    def authenticate(self, request):
        result = super().authenticate(request)
        if result is not None:
            user, _auth = result
            # This is the single authority for request.tenant on JWT requests.
            # It has to run here rather than in TenantMiddleware because JWT
            # auth happens inside DRF view dispatch, i.e. *after* middleware —
            # so at middleware time request.user is still anonymous and a
            # middleware-side resolver would never fire for a real token.
            # resolve_tenant_for_request also knows how to honour SUPER_ADMIN's
            # explicitly-supplied tenant (see core/tenant_resolution.py).
            request.tenant = resolve_tenant_for_request(user, request)
        return result
