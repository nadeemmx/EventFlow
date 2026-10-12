from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from config.api_router import api_router
from core.api_errors import api_not_found
from core.health import health_check, readiness_check, liveness_check

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/", include(api_router.urls)),
    path("health/", health_check, name="health"),
    path("ready/", readiness_check, name="readiness"),
    path("live/", liveness_check, name="liveness"),
    # Keep this last: it must only catch API paths the router above did not
    # match, otherwise it would shadow real endpoints.
    path("api/v1/<path:unmatched>", api_not_found),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
