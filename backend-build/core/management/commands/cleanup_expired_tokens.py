import logging
from django.core.management.base import BaseCommand
from django.utils import timezone
from rest_framework_simplejwt.token_blacklist.models import OutstandingToken, BlacklistedToken
from django.contrib.sessions.models import Session

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Clean up expired tokens and stale sessions"

    def handle(self, *args, **options):
        now = timezone.now()

        expired_outstanding = OutstandingToken.objects.filter(expires_at__lt=now)
        count_outstanding, _ = expired_outstanding.delete()

        cutoff = now - timezone.timedelta(days=90)
        old_blacklisted = BlacklistedToken.objects.filter(
            token__expires_at__lt=cutoff
        ).select_related("token")
        count_blacklisted, _ = old_blacklisted.delete()

        expired_sessions = Session.objects.filter(expire_date__lt=now)
        count_sessions, _ = expired_sessions.delete()

        from apps.authentication.models import PasswordResetCode
        expired_codes = PasswordResetCode.objects.filter(
            is_used=False,
            created_at__lt=now - timezone.timedelta(hours=24),
        )
        count_codes, _ = expired_codes.delete()

        self.stdout.write(
            self.style.SUCCESS(
                f"Cleaned up {count_outstanding} tokens, "
                f"{count_blacklisted} old blacklisted, "
                f"{count_sessions} sessions, "
                f"{count_codes} reset codes"
            )
        )
