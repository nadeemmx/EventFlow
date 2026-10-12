"""JSON error responses for routes Django's default handlers would render as
HTML."""
from django.http import JsonResponse


def api_not_found(request, *args, **kwargs):
    """Unknown ``/api/v1/...`` path.

    Django's default 404 handler rendered an HTML page for unmatched API
    routes, so a JSON client tripped over the content type before it ever
    reached the status code (QA-TEST-REPORT-ROLES.md F-6). This is registered
    as a catch-all *after* the router, so it only fires for paths the API did
    not match; ``/admin/`` and the rest of the site keep Django's HTML 404.

    The body matches the project's envelope in ``core/responses.py``.
    """
    return JsonResponse(
        {"success": False, "message": "Not found.", "errors": {}},
        status=404,
    )
