from django.conf import settings
from django.utils import timezone

from repositories.base import BaseRepository
from apps.users.models import User, UserSession


class UserRepository(BaseRepository):
    model = User

    def get_by_email(self, email):
        return self.model.objects.filter(email=email).first()

    def get_active_users_count(self, tenant):
        return self.model.objects.filter(tenant=tenant, is_active=True).count()

    def create_session(self, user, access_token, refresh_token, device_name="", ip_address=""):
        refresh_lifetime = settings.SIMPLE_JWT["REFRESH_TOKEN_LIFETIME"]
        return UserSession.objects.create(
            user=user,
            access_token=access_token,
            refresh_token=refresh_token,
            device_name=device_name,
            ip_address=ip_address,
            expires_at=timezone.now() + refresh_lifetime,
        )

    def get_session_by_refresh_token(self, refresh_token):
        return UserSession.objects.filter(refresh_token=refresh_token).first()

    def delete_session(self, refresh_token):
        UserSession.objects.filter(refresh_token=refresh_token).delete()
