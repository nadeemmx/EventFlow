import logging
from django.contrib.auth.backends import ModelBackend
from apps.users.models import User

logger = logging.getLogger("authentication")


class EmailOrMobileBackend(ModelBackend):
    def authenticate(self, request, email=None, password=None, **kwargs):
        logger.warning("[AUTH DEBUG] authenticate() called — email=%r, password_provided=%s", email, password is not None)

        # Try by email
        try:
            user = User.objects.get(email=email)
            logger.warning("[AUTH DEBUG] User found by email: id=%s, email=%s, is_active=%s", user.id, user.email, user.is_active)
        except User.DoesNotExist:
            logger.warning("[AUTH DEBUG] No user with email=%r, trying mobile", email)
            try:
                user = User.objects.get(mobile=email)
                logger.warning("[AUTH DEBUG] User found by mobile: id=%s, email=%s, is_active=%s", user.id, user.email, user.is_active)
            except User.DoesNotExist:
                logger.warning("[AUTH DEBUG] No user found by email or mobile=%r", email)
                return None

        # Check password
        pw_ok = user.check_password(password)
        logger.warning("[AUTH DEBUG] check_password() => %s, is_active=%s", pw_ok, user.is_active)

        if pw_ok and user.is_active:
            logger.warning("[AUTH DEBUG] Authentication SUCCESS for %s", user.email)
            return user

        logger.warning("[AUTH DEBUG] Authentication FAILED — check_password=%s, is_active=%s", pw_ok, user.is_active)
        return None
