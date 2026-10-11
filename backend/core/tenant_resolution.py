"""Resolve the tenant for a request, centrally.

Kept separate from the middleware/auth classes so both can share one
implementation. See ``core/authentication.TenantJWTAuthentication`` for why
this runs after JWT auth rather than in middleware.
"""
from core.choices import UserRole


def resolve_tenant_for_request(user, request):
    """Return the ``Tenant`` a request operates on, or ``None``.

    For ordinary tenant users this is simply their own tenant.

    ``SUPER_ADMIN`` is the platform role and has no tenant of its own
    (``users.tenant`` is nullable). Every tenant-scoped viewset writes
    ``serializer.save(tenant=request.tenant)`` and every repository filters
    on it, so leaving ``request.tenant`` as ``None`` made *every* SUPER_ADMIN
    create raise ``NOT NULL constraint failed`` (HTTP 500) and every list
    return nothing. See QA-TEST-REPORT-ROLES.md F-1.

    Rather than making ``tenant`` nullable — which would weaken the tenancy
    invariant that tenant isolation depends on — SUPER_ADMIN names the
    tenant explicitly and we resolve it here, so all 13 viewsets, every
    service, and the serializer FK-scoping (``scope_fields_to_tenant``)
    inherit the right value with no per-viewset changes:

    * writes (POST/PUT/PATCH): a ``tenant`` field in a JSON/form body
    * reads (GET): a ``?tenant=<id>`` query parameter

    It fails closed: if SUPER_ADMIN omits the field, or names a tenant that
    does not exist, the result is ``None`` and the request behaves exactly as
    before (empty queryset / NOT NULL rejection) rather than silently
    defaulting to some other tenant's data.
    """
    if user is None or not getattr(user, "is_authenticated", False):
        return None

    tenant = getattr(user, "tenant", None)
    if tenant is not None:
        return tenant
    if getattr(user, "role", None) != UserRole.SUPER_ADMIN:
        return None
    return _resolve_superadmin_tenant(request)


def _resolve_superadmin_tenant(request):
    tenant_id = None
    if request.method in ("POST", "PUT", "PATCH"):
        tenant_id = _tenant_id_from_body(request)
    if tenant_id is None:
        raw = request.GET.get("tenant") if hasattr(request, "GET") else None
        if raw is not None and str(raw).isdigit():
            tenant_id = int(raw)
    if tenant_id is None:
        return None

    from apps.tenants.models import Tenant

    # is_active is intentionally not filtered here: SUPER_ADMIN is the
    # platform operator and may legitimately target a suspended tenant.
    return Tenant.objects.filter(pk=tenant_id).first()


def _tenant_id_from_body(request):
    """Pull ``tenant`` out of the request body without breaking DRF parsing.

    ``request.data`` (DRF) is the parsed payload. Only JSON and
    form-urlencoded are read; multipart is skipped so file uploads (invoice
    PDFs, venue images) are never buffered into memory — the web client
    always sends JSON for creates.
    """
    try:
        payload = request.data
    except Exception:
        return None
    if payload is None or not hasattr(payload, "get"):
        return None
    return _coerce_tenant_id(payload.get("tenant"))


def _coerce_tenant_id(raw):
    if isinstance(raw, bool):
        return None
    if isinstance(raw, int):
        return raw
    if isinstance(raw, str) and raw.isdigit():
        return int(raw)
    return None
