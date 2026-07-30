import pytest
from django.test import RequestFactory
from core.logging_middleware import RequestLoggingMiddleware, PerformanceTimingMiddleware


class TestMiddleware:
    def setup_method(self):
        self.factory = RequestFactory()

    def test_request_logging_sets_request_id(self):
        def get_response(request):
            return type("Response", (), {"status_code": 200, "__setitem__": lambda s, k, v: None})()

        middleware = RequestLoggingMiddleware(get_response)
        request = self.factory.get("/api/v1/bookings/")
        response = middleware(request)
        assert hasattr(request, "request_id")

    def test_performance_timing_adds_header(self):
        def get_response(request):
            resp_cls = type("Response", (), {
                "status_code": 200,
                "headers": {},
                "__setitem__": lambda s, k, v: s.headers.update({k: v}),
            })
            return resp_cls()

        middleware = PerformanceTimingMiddleware(get_response)
        request = self.factory.get("/api/v1/bookings/")
        response = middleware(request)
        assert "X-Response-Time-Ms" in response.headers
