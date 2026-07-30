from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from config.api_router import api_router
from core.health import health_check, readiness_check, liveness_check

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/", include(api_router.urls)),
    path("health/", health_check, name="health"),
    path("ready/", readiness_check, name="readiness"),
    path("live/", liveness_check, name="liveness"),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
