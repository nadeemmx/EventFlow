import pytest
from django.contrib.auth import get_user_model
from django.db import IntegrityError
from django.utils import timezone
from apps.users.models import UserSession
from tests.factories import UserFactory, TenantFactory
from core.choices import UserRole

User = get_user_model()


@pytest.mark.django_db
class TestUserModel:
    def test_create_user(self):
        tenant = TenantFactory()
        user = User.objects.create_user(
            email="test@example.com",
            password="secure123",
            full_name="Test User",
            tenant=tenant,
        )
        assert user.email == "test@example.com"
        assert user.full_name == "Test User"
        assert user.tenant == tenant
        assert user.check_password("secure123")
        assert user.is_active is True
        assert user.is_staff is False

    def test_create_superuser(self):
        user = User.objects.create_superuser(
            email="admin@example.com",
            password="admin123",
            full_name="Admin User",
        )
        assert user.is_superuser is True
        assert user.is_staff is True
        assert user.role == UserRole.SUPER_ADMIN

    def test_string_representation(self):
        user = UserFactory(full_name="John Doe", email="john@example.com")
        assert str(user) == "John Doe (john@example.com)"

    def test_email_unique_constraint(self):
        UserFactory(email="dupe@example.com")
        with pytest.raises(IntegrityError):
            UserFactory(email="dupe@example.com")

    def test_email_required(self):
        with pytest.raises(ValueError, match="Email is required"):
            User.objects.create_user(email="", password="p")

    def test_default_role_is_staff(self):
        user = UserFactory()
        assert user.role == UserRole.MANAGER

    def test_user_tenant_relationship(self):
        tenant = TenantFactory()
        user = UserFactory(tenant=tenant)
        assert user.tenant == tenant
        assert list(tenant.user_set.all()) == [user]


@pytest.mark.django_db
class TestUserSessionModel:
    def test_create_session(self):
        user = UserFactory()
        session = UserSession.objects.create(
            user=user,
            access_token="abc123",
            refresh_token="def456",
            device_name="iPhone",
            ip_address="192.168.1.1",
            expires_at=timezone.now() + timezone.timedelta(hours=1),
        )
        assert session.user == user
        assert session.access_token == "abc123"
        assert session.device_name == "iPhone"

    def test_string_representation(self):
        user = UserFactory(email="test@example.com")
        session = UserSession.objects.create(
            user=user,
            access_token="tok",
            refresh_token="ref",
            expires_at=timezone.now() + timezone.timedelta(hours=1),
        )
        assert str(session) == "Session - test@example.com"

    def test_session_related_name(self):
        user = UserFactory()
        s1 = UserSession.objects.create(
            user=user, access_token="a", refresh_token="b",
            expires_at=timezone.now() + timezone.timedelta(hours=1),
        )
        s2 = UserSession.objects.create(
            user=user, access_token="c", refresh_token="d",
            expires_at=timezone.now() + timezone.timedelta(hours=1),
        )
        assert list(user.sessions.all()) == [s2, s1]

    def test_cascade_delete(self):
        user = UserFactory()
        UserSession.objects.create(
            user=user, access_token="a", refresh_token="b",
            expires_at=timezone.now() + timezone.timedelta(hours=1),
        )
        assert UserSession.objects.count() == 1
        user.delete()
        assert UserSession.objects.count() == 0
