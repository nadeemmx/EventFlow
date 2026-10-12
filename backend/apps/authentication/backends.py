import logging
from django.contrib.auth.backends import ModelBackend
from apps.users.models import User

logger = logging.getLogger("authentication")


class EmailOrMobileBackend(ModelBackend):
    def authenticate(self, request, email=None, password=None, **kwargs):
        if email is None:
            email = kwargs.get("username")
        user = None

        if email:
            user = User.objects.filter(email=email).first()
            if user is None:
                user = User.objects.filter(mobile=email).first()

        if user is None:
            return None

        if user.check_password(password) and user.is_active:
            return user

        return None
