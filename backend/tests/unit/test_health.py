import json
import pytest
from django.test import RequestFactory
from core.health import health_check, readiness_check, liveness_check


class TestHealthEndpoints:
    def setup_method(self):
        self.factory = RequestFactory()

    def test_health_check(self):
        request = self.factory.get("/health/")
        response = health_check(request)
        assert response.status_code == 200
        data = json.loads(response.content)
        assert data["status"] == "ok"
        assert "version" in data
        assert "timestamp" in data

    def test_liveness_check(self):
        request = self.factory.get("/live/")
        response = liveness_check(request)
        assert response.status_code == 200
        data = json.loads(response.content)
        assert data["status"] == "alive"

    @pytest.mark.django_db
    def test_readiness_check(self):
        request = self.factory.get("/ready/")
        response = readiness_check(request)
        assert response.status_code == 200
        data = json.loads(response.content)
        assert data["status"] == "ok"
        assert data["checks"]["database"] is True
