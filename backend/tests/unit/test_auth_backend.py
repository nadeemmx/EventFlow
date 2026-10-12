from django.contrib.auth import authenticate
from django.test import TestCase

from apps.tenants.models import Tenant
from apps.users.models import User
from core.choices import UserRole


class EmailOrMobileBackendTests(TestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Alpha Venue", owner_name="Owner",
            email="alpha@test.com", mobile="1111111111",
        )
        self.user = User.objects.create_user(
            email="admin@test.com", password="StrongPass123!",
            full_name="Admin User", mobile="+919000000001",
            tenant=self.tenant, role=UserRole.OWNER,
        )

    def test_authenticates_via_username_kwarg(self):
        user = authenticate(username="admin@test.com", password="StrongPass123!")
        self.assertEqual(user, self.user)

    def test_authenticates_via_email_kwarg(self):
        user = authenticate(email="admin@test.com", password="StrongPass123!")
        self.assertEqual(user, self.user)

    def test_authenticates_via_mobile(self):
        user = authenticate(username="+919000000001", password="StrongPass123!")
        self.assertEqual(user, self.user)

    def test_wrong_password_returns_none(self):
        user = authenticate(username="admin@test.com", password="wrongpassword")
        self.assertIsNone(user)

    def test_unknown_identifier_returns_none(self):
        user = authenticate(username="nobody@test.com", password="StrongPass123!")
        self.assertIsNone(user)

    def test_duplicate_mobile_does_not_raise(self):
        User.objects.create_user(
            email="second@test.com", password="StrongPass123!",
            full_name="Second User", mobile="+919000000001",
            tenant=self.tenant, role=UserRole.STAFF,
        )
        user = authenticate(username="+919000000001", password="StrongPass123!")
        self.assertIsNotNone(user)
        self.assertEqual(user.mobile, "+919000000001")

    def test_inactive_user_returns_none(self):
        self.user.is_active = False
        self.user.save()
        user = authenticate(username="admin@test.com", password="StrongPass123!")
        self.assertIsNone(user)
