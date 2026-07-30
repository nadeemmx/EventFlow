from django.contrib.auth import authenticate
from django.utils import timezone
from rest_framework_simplejwt.tokens import RefreshToken
from repositories.user_repository import UserRepository
from repositories.audit_repository import AuditRepository
from core.validators import validate_password_strength
from core.exceptions import ValidationException
from core.utils import get_client_ip
from core.choices import UserRole
from core.brute_force import BruteForceProtection


class AuthService:
    def __init__(self):
        self.user_repo = UserRepository()
        self.audit_repo = AuditRepository()

    def login(self, email, password, request=None):
        ip = get_client_ip(request) if request else ""
        if BruteForceProtection.is_locked_out(email, ip):
            raise ValidationException("Account temporarily locked due to multiple failed attempts")
        user = authenticate(email=email, password=password)
        if not user:
            BruteForceProtection.record_failed_attempt(email, ip)
            raise ValidationException("Invalid email or password")
        if not user.is_active:
            raise ValidationException("Account is deactivated")
        if user.role != UserRole.SUPER_ADMIN:
            tenant = user.tenant
            if tenant and tenant.status not in ["ACTIVE", "TRIAL"]:
                raise ValidationException("Tenant account is inactive")
        BruteForceProtection.clear_attempts(email, ip)
        refresh = RefreshToken.for_user(user)
        access_token = str(refresh.access_token)
        refresh_token = str(refresh)
        self.user_repo.create_session(
            user, access_token, refresh_token,
            device_name=request.META.get("HTTP_USER_AGENT", "") if request else "",
            ip_address=ip,
        )
        self.audit_repo.log(
            tenant=user.tenant, user=user,
            module="AUTH", action="LOGIN",
            ip_address=ip,
        )
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "user": {
                "id": user.id,
                "full_name": user.full_name,
                "email": user.email,
                "role": user.role,
                "tenant_id": user.tenant_id,
            },
        }

    def refresh(self, refresh_token):
        from rest_framework_simplejwt.tokens import RefreshToken as JWTRefreshToken
        try:
            token = JWTRefreshToken(refresh_token)
            user_id = token.payload.get("user_id")
            user = self.user_repo.get_by_id(user_id)
            new_refresh = JWTRefreshToken.for_user(user)
            return {
                "access_token": str(new_refresh.access_token),
                "refresh_token": str(new_refresh),
            }
        except Exception:
            raise ValidationException("Invalid or expired refresh token")

    def logout(self, user, refresh_token):
        from rest_framework_simplejwt.tokens import RefreshToken as JWTRefreshToken
        try:
            token = JWTRefreshToken(refresh_token)
            token.blacklist()
        except Exception:
            raise ValidationException("Invalid refresh token")
        self.user_repo.delete_session(refresh_token)
        self.audit_repo.log(
            tenant=user.tenant, user=user,
            module="AUTH", action="LOGOUT",
        )

    def change_password(self, user, current_password, new_password):
        if not user.check_password(current_password):
            raise ValidationException("Current password is incorrect")
        validate_password_strength(new_password)
        user.set_password(new_password)
        user.save()
        self.audit_repo.log(
            tenant=user.tenant, user=user,
            module="AUTH", action="CHANGE_PASSWORD",
        )

    def forgot_password(self, email):
        from apps.authentication.models import PasswordResetCode
        user = self.user_repo.get_by_email(email)
        if not user:
            return
        reset_code, raw_code = PasswordResetCode.create_for_user(user)
        from django.core.mail import send_mail
        from django.conf import settings
        try:
            send_mail(
                subject="Password Reset - EventFlow",
                message=f"Your password reset code: {raw_code}\n\nUse this code to reset your password.",
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                fail_silently=True,
            )
        except Exception:
            pass

    def reset_password(self, code, password):
        from apps.authentication.models import PasswordResetCode
        from django.utils import timezone
        try:
            reset_codes = PasswordResetCode.objects.filter(
                is_used=False,
                created_at__gte=timezone.now() - timezone.timedelta(hours=1),
            ).select_related("user")
            reset_code = None
            for rc in reset_codes:
                if rc.verify_code(code):
                    reset_code = rc
                    break
            if not reset_code:
                raise ValidationException("Invalid or expired reset code")
            user = reset_code.user
            validate_password_strength(password)
            user.set_password(password)
            user.save()
            reset_code.is_used = True
            reset_code.save()
            self.audit_repo.log(
                tenant=user.tenant, user=user,
                module="AUTH", action="RESET_PASSWORD",
            )
        except ValidationException:
            raise
        except Exception:
            raise ValidationException("Invalid or expired reset code")
