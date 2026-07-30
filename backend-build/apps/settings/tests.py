import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from apps.tenants.models import Tenant
from apps.users.models import User
from core.choices import UserRole


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def tenant(db):
    return Tenant.objects.create(
        business_name="Test Venue",
        owner_name="Test Owner",
        email="owner@test.com",
        mobile="+911234567890",
    )


@pytest.fixture
def user(tenant, db):
    return User.objects.create_user(
        email="admin@test.com",
        password="testpass123",
        full_name="Admin User",
        tenant=tenant,
        role=UserRole.OWNER,
    )


@pytest.fixture
def auth_client(api_client, user):
    api_client.force_authenticate(user=user)
    return api_client


class TestSettingsAPI:
    SETTINGS_ENDPOINTS = [
        "payment-gateway", "whatsapp", "email", "invoice",
        "booking", "notifications", "security", "branding",
    ]

    def test_get_all_settings_returns_valid_data(self, auth_client):
        for ep in self.SETTINGS_ENDPOINTS:
            url = reverse(f"settings-{ep.replace('_', '-')}")
            response = auth_client.get(url)
            assert response.status_code == status.HTTP_200_OK, f"GET {ep} failed: {response.data}"
            assert response.data["success"] is True

    def test_update_all_settings(self, auth_client):
        test_payloads = {
            "payment-gateway": {"is_active": True, "environment": "test"},
            "whatsapp": {"is_active": True, "send_notifications": False},
            "email": {"is_active": True, "smtp_host": "smtp.example.com"},
            "invoice": {"prefix": "INV-2024", "due_days": 15},
            "booking": {"auto_confirm": True, "buffer_days": 2},
            "notifications": {"notify_on_booking": False, "reminder_hours": 48},
            "security": {"two_factor_enabled": True, "session_timeout_minutes": 60},
            "branding": {"primary_color": "#FF0000"},
        }
        for ep, payload in test_payloads.items():
            url = reverse(f"settings-{ep}")
            response = auth_client.put(url, payload, format="json")
            assert response.status_code == status.HTTP_200_OK, f"PUT {ep} failed: {response.data}"
            assert response.data["success"] is True
            for key, val in payload.items():
                assert str(response.data["data"].get(key)) == str(val), f"Mismatch on {ep}.{key}"

    def test_get_organization(self, auth_client, tenant):
        url = reverse("settings-organization")
        response = auth_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert response.data["data"]["business_name"] == tenant.business_name

    def test_update_organization(self, auth_client):
        url = reverse("settings-organization")
        payload = {"business_name": "Updated Venue"}
        response = auth_client.put(url, payload, format="json")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["data"]["business_name"] == "Updated Venue"

    def test_get_profile(self, auth_client, user):
        url = reverse("settings-profile")
        response = auth_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert response.data["data"]["email"] == user.email

    def test_update_profile(self, auth_client):
        url = reverse("settings-profile")
        payload = {"full_name": "Updated Name"}
        response = auth_client.put(url, payload, format="json")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["data"]["full_name"] == "Updated Name"

    def test_user_crud(self, auth_client, tenant):
        list_url = reverse("settings-users")

        create_payload = {
            "full_name": "Staff User",
            "email": "staff@test.com",
            "mobile": "+911111111111",
            "password": "testpass123",
            "role": UserRole.STAFF,
        }
        response = auth_client.post(list_url, create_payload, format="json")
        assert response.status_code == status.HTTP_201_CREATED
        user_id = response.data["data"]["id"]

        response = auth_client.get(list_url)
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["data"]) >= 1

        update_url = reverse("settings-update-user", args=[user_id])
        response = auth_client.put(update_url, {"full_name": "Updated Staff"}, format="json")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["data"]["full_name"] == "Updated Staff"

        activate_url = reverse("settings-activate-user", args=[user_id])
        response = auth_client.post(activate_url)
        assert response.status_code == status.HTTP_200_OK

        deactivate_url = reverse("settings-deactivate-user", args=[user_id])
        response = auth_client.post(deactivate_url)
        assert response.status_code == status.HTTP_200_OK
        assert response.data["data"]["is_active"] is False

        delete_url = reverse("settings-delete-user", args=[user_id])
        response = auth_client.delete(delete_url)
        assert response.status_code == status.HTTP_200_OK

    def test_roles_list(self, auth_client):
        url = reverse("settings-roles")
        response = auth_client.get(url)
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["data"]) == len(UserRole.choices)

    def test_subscription(self, auth_client):
        url = reverse("settings-subscription")
        response = auth_client.get(url)
        assert response.status_code == status.HTTP_200_OK
