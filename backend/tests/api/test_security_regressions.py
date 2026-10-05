"""Regression tests for audit fixes (SEC-04, SEC-05, SEC-08, SEC-09).

Each test fails against the pre-fix code:
- SEC-04: ``User`` was imported only inside the SUPER_ADMIN branch, so a
  non-super-admin listing users raised ``UnboundLocalError`` (HTTP 500).
- SEC-05: ``UserService.create_user`` raised ``KeyError`` on a missing
  password (HTTP 500) and ``update_user`` stored the raw password.
- SEC-08: ``int(query_params["page"])`` raised ``ValueError`` (HTTP 500)
  for inputs like ``?page=abc``.
- SEC-09: domain exceptions were all mapped to HTTP 400.
"""
from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase

from apps.tenants.models import Tenant, TenantSettings
from core.choices import UserRole

User = get_user_model()


class SecurityRegressionTestBase(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Audit Venue",
            owner_name="Owner",
            email="audit-owner@test.com",
            mobile="1111111111",
        )
        TenantSettings.objects.create(tenant=self.tenant)
        self.owner = User.objects.create_user(
            email="audit-owner@test.com",
            password="OwnerPass123!",
            full_name="Owner",
            tenant=self.tenant,
            role=UserRole.OWNER,
        )
        self.staff_user = User.objects.create_user(
            email="audit-staff@test.com",
            password="StaffPass123!",
            full_name="Staff",
            tenant=self.tenant,
            role=UserRole.STAFF,
        )
        self.client.force_authenticate(user=self.owner)


class UserListRegressionTests(SecurityRegressionTestBase):
    """SEC-04: module-level import of User in users/views.py."""

    def test_non_super_admin_can_list_users(self):
        response = self.client.get("/api/v1/users/")
        self.assertEqual(response.status_code, 200)
        emails = [row["email"] for row in response.data["results"]]
        self.assertIn("audit-staff@test.com", emails)

    def test_super_admin_can_list_users(self):
        super_admin = User.objects.create_superuser(
            email="audit-super@test.com",
            password="SuperPass123!",
            full_name="Super Admin",
        )
        self.client.force_authenticate(user=super_admin)
        response = self.client.get("/api/v1/users/")
        self.assertEqual(response.status_code, 200)
        self.assertGreaterEqual(len(response.data["results"]), 2)


class UserPasswordRegressionTests(SecurityRegressionTestBase):
    """SEC-05: password hashing / missing-password handling in user_service."""

    def test_create_user_without_password_is_rejected_not_500(self):
        response = self.client.post(
            "/api/v1/users/",
            {
                "full_name": "No Password",
                "email": "audit-nopass@test.com",
                "mobile": "2222222222",
                "role": UserRole.STAFF,
            },
        )
        self.assertEqual(response.status_code, 400)
        self.assertFalse(response.data["success"])
        self.assertIn("Password", response.data["message"])
        self.assertFalse(
            User.objects.filter(email="audit-nopass@test.com").exists()
        )

    def test_create_user_with_password_stores_hash(self):
        response = self.client.post(
            "/api/v1/users/",
            {
                "full_name": "New User",
                "email": "audit-newuser@test.com",
                "mobile": "3333333333",
                "role": UserRole.STAFF,
                "password": "NewUserPass123!",
            },
        )
        self.assertEqual(response.status_code, 201)
        created = User.objects.get(email="audit-newuser@test.com")
        self.assertNotEqual(created.password, "NewUserPass123!")
        self.assertTrue(created.check_password("NewUserPass123!"))

    def test_update_user_password_is_hashed_not_stored_plaintext(self):
        response = self.client.patch(
            f"/api/v1/users/{self.staff_user.id}/",
            {"password": "ChangedPass456!"},
        )
        self.assertEqual(response.status_code, 200)
        self.staff_user.refresh_from_db()
        self.assertNotEqual(self.staff_user.password, "ChangedPass456!")
        self.assertTrue(self.staff_user.check_password("ChangedPass456!"))

    def test_update_user_without_password_keeps_existing_password(self):
        response = self.client.patch(
            f"/api/v1/users/{self.staff_user.id}/",
            {"full_name": "Renamed Staff"},
        )
        self.assertEqual(response.status_code, 200)
        self.staff_user.refresh_from_db()
        self.assertEqual(self.staff_user.full_name, "Renamed Staff")
        self.assertTrue(self.staff_user.check_password("StaffPass123!"))


class SettingsPaginationRegressionTests(SecurityRegressionTestBase):
    """SEC-08: unsafe int() parsing of pagination params in settings/views."""

    def test_invalid_page_param_does_not_raise(self):
        response = self.client.get(
            "/api/v1/settings/users/", {"page": "abc"}
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn("results", response.data["data"])

    def test_invalid_page_size_param_does_not_raise(self):
        response = self.client.get(
            "/api/v1/settings/users/", {"page_size": "abc"}
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn("results", response.data["data"])

    def test_empty_page_param_falls_back_to_default(self):
        response = self.client.get("/api/v1/settings/users/", {"page": ""})
        self.assertEqual(response.status_code, 200)

    def test_zero_and_negative_page_fall_back_to_first_page(self):
        for value in ("0", "-3"):
            response = self.client.get(
                "/api/v1/settings/users/", {"page": value}
            )
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.data["data"]["page"], 1)


class DomainExceptionStatusRegressionTests(SecurityRegressionTestBase):
    """SEC-09: domain exceptions map to their proper HTTP status codes."""

    def test_missing_user_returns_404(self):
        response = self.client.put(
            "/api/v1/settings/999999/update_user/",
            {"full_name": "Ghost"},
            format="json",
        )
        self.assertEqual(response.status_code, 404)
        self.assertFalse(response.data["success"])

    def test_domain_conflict_returns_409(self):
        # Venue double-booking raises ConflictException deep in the
        # service layer; only ValidationException is caught by the view,
        # so the exception handler must map it to 409 (not 400).
        from datetime import timedelta

        from django.utils import timezone

        from apps.bookings.models import Booking
        from apps.customers.models import Customer
        from apps.venues.models import Venue
        from core.choices import BookingStatus, EventType

        venue = Venue.objects.create(
            tenant=self.tenant, name="Conflict Hall", capacity=500
        )
        customer = Customer.objects.create(
            tenant=self.tenant,
            full_name="Conflict Customer",
            mobile="5555555555",
        )
        event_date = timezone.now().date() + timedelta(days=45)
        Booking.objects.create(
            tenant=self.tenant,
            booking_number="VF-2026-999999",
            venue=venue,
            customer=customer,
            event_type=EventType.WEDDING,
            event_date=event_date,
            guest_count=10,
            total_amount=1000,
            status=BookingStatus.CONFIRMED,
        )
        response = self.client.post(
            "/api/v1/bookings/",
            {
                "venue": venue.id,
                "customer": customer.id,
                "event_type": "WEDDING",
                "event_date": str(event_date),
                "guest_count": 10,
                "total_amount": 1000,
            },
        )
        self.assertEqual(response.status_code, 409)
        self.assertFalse(response.data["success"])
