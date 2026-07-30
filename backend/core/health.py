import os
import django
from django.conf import settings
from django.db import connection
from django.http import JsonResponse
from django.views.decorators.http import require_GET
from django.views.decorators.cache import never_cache
import time


@require_GET
@never_cache
def health_check(request):
    return JsonResponse({
        "status": "ok",
        "version": getattr(settings, "APP_VERSION", "1.0.0"),
        "timestamp": time.time(),
    })


@require_GET
@never_cache
def readiness_check(request):
    checks = {
        "database": False,
        "migrations": False,
    }
    
    try:
        connection.ensure_connection()
        checks["database"] = True
    except Exception:
        pass
    
    try:
        from django.db.migrations.executor import MigrationExecutor
        executor = MigrationExecutor(connection)
        plan = executor.migration_plan(executor.loader.graph.leaf_nodes())
        checks["migrations"] = len(plan) == 0
    except Exception:
        pass
    
    all_ok = all(checks.values())
    status_code = 200 if all_ok else 503
    
    return JsonResponse(
        {"status": "ok" if all_ok else "degraded", "checks": checks},
        status=status_code,
    )


@require_GET
@never_cache
def liveness_check(request):
    return JsonResponse({"status": "alive"})
