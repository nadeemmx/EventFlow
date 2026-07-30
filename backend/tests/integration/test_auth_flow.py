from rest_framework.test import APITestCase
from apps.tenants.models import Tenant
from apps.users.models import User


class TestAuthFlow(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Test Venue", owner_name="Owner",
            email="test@test.com", mobile="9999999999",
        )
        self.user = User.objects.create_user(
            email="admin@test.com", password="StrongPass123",
            full_name="Admin", tenant=self.tenant, role="OWNER",
        )

    def test_login_success(self):
        response = self.client.post("/api/v1/auth/login/", {
            "email": "admin@test.com",
            "password": "StrongPass123",
        })
        self.assertEqual(response.status_code, 200)
        self.assertIn("access_token", response.data["data"])
        self.assertIn("refresh_token", response.data["data"])
        self.assertIn("user", response.data["data"])

    def test_login_invalid_password(self):
        response = self.client.post("/api/v1/auth/login/", {
            "email": "admin@test.com",
            "password": "wrongpassword",
        })
        self.assertEqual(response.status_code, 401)

    def test_login_missing_fields(self):
        response = self.client.post("/api/v1/auth/login/", {}, content_type="application/json")
        self.assertEqual(response.status_code, 400)

    def test_refresh_token(self):
        login_response = self.client.post("/api/v1/auth/login/", {
            "email": "admin@test.com",
            "password": "StrongPass123",
        })
        refresh_token = login_response.data["data"]["refresh_token"]
        response = self.client.post("/api/v1/auth/refresh/", {
            "refresh_token": refresh_token,
        })
        self.assertEqual(response.status_code, 200)
        self.assertIn("access_token", response.data["data"])

    def test_profile_authenticated(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.get("/api/v1/profile/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["data"]["email"], "admin@test.com")

    def test_profile_unauthenticated(self):
        response = self.client.get("/api/v1/profile/")
        self.assertEqual(response.status_code, 401)

    def test_change_password(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.post("/api/v1/auth/change-password/", {
            "current_password": "StrongPass123",
            "new_password": "NewStrong456",
            "confirm_password": "NewStrong456",
        })
        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password("NewStrong456"))

    def test_logout(self):
        login_response = self.client.post("/api/v1/auth/login/", {
            "email": "admin@test.com",
            "password": "StrongPass123",
        })
        access = login_response.data["data"]["access_token"]
        refresh = login_response.data["data"]["refresh_token"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
        response = self.client.post("/api/v1/auth/logout/", {
            "refresh_token": refresh,
        })
        self.assertEqual(response.status_code, 200)

    def test_forgot_password(self):
        response = self.client.post("/api/v1/auth/forgot-password/", {
            "email": "admin@test.com",
        })
        self.assertEqual(response.status_code, 200)
