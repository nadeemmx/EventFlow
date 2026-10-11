import uuid
import time
import logging
import json


class RequestLoggingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request_id = str(uuid.uuid4())[:8]
        request.request_id = request_id
        start_time = time.time()

        response = self.get_response(request)

        duration = time.time() - start_time
        extra = {
            "request_id": request_id,
            "method": request.method,
            "path": request.path,
            "status": response.status_code,
            "duration_ms": round(duration * 1000, 2),
            "user": str(request.user.id) if hasattr(request, "user") and request.user.is_authenticated else "anonymous",
        }

        logger = logging.getLogger("api")
        if response.status_code >= 500:
            logger.error("Request failed", extra=extra)
        elif response.status_code >= 400:
            logger.warning("Request warning", extra=extra)
        else:
            logger.info("Request ok", extra=extra)

        response["X-Request-ID"] = request_id
        return response


class PerformanceTimingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        start = time.time()
        response = self.get_response(request)
        elapsed = time.time() - start
        response["X-Response-Time-Ms"] = str(round(elapsed * 1000, 2))
        return response
