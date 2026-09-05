import logging
from django.contrib.auth.backends import ModelBackend
from apps.users.models import User

logger = logging.getLogger("authentication")


class EmailOrMobileBackend(ModelBackend):
    def authenticate(self, request, email=None, password=None, **kwargs):
        user = None

        # Try by email
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            # Try by mobile
            try:
                user = User.objects.get(mobile=email)
            except User.DoesNotExist:
                return None

        if user is None:
            return None

        if user.check_password(password) and user.is_active:
            return user

        return None
