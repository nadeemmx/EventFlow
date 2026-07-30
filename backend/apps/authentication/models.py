from django.db import models
from django.conf import settings
from django.contrib.auth.hashers import make_password, check_password
import secrets


class PasswordResetCode(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, db_index=True)
    code = models.CharField(max_length=255, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    is_used = models.BooleanField(default=False)

    class Meta:
        db_table = "password_reset_codes"
        verbose_name = "Password Reset Code"
        verbose_name_plural = "Password Reset Codes"
        ordering = ["-created_at"]

    @classmethod
    def create_for_user(cls, user):
        raw_code = secrets.token_urlsafe(32)
        hashed = make_password(raw_code)
        return cls.objects.create(user=user, code=hashed), raw_code

    def verify_code(self, raw_code):
        return check_password(raw_code, self.code)
