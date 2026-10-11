from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from apps.audit_logs.models import AuditLog


class Command(BaseCommand):
    help = "Clean up audit logs older than 1 year"

    def handle(self, *args, **options):
        cutoff = timezone.now() - timedelta(days=365)
        deleted, _ = AuditLog.objects.filter(created_at__lte=cutoff).delete()
        self.stdout.write(f"Cleaned up {deleted} old audit logs")
