import os
import sys
import logging
from django.core.management.base import BaseCommand
from django.conf import settings
from django.db import connection
from django.core.management import call_command

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = "Validate deployment is configured correctly for production"

    def handle(self, *args, **options):
        errors = []
        warnings = []
        success = []

        # Check SECRET_KEY
        sk = settings.SECRET_KEY
        if not sk or sk == "insecure-dev-key-change-in-production":
            errors.append("SECRET_KEY is insecure or not set")
        elif len(sk) < 32:
            warnings.append("SECRET_KEY is shorter than 32 characters")
        else:
            success.append("SECRET_KEY is set and looks secure")

        # Check DEBUG
        if settings.DEBUG:
            errors.append("DEBUG is enabled - must be False in production")
        else:
            success.append("DEBUG is disabled")

        # Check database connectivity
        try:
            connection.ensure_connection()
            success.append("Database connection OK")
        except Exception as e:
            errors.append(f"Database connection failed: {e}")

        # Check static files
        static_root = settings.STATIC_ROOT
        if static_root:
            if os.path.exists(static_root):
                files = os.listdir(static_root)
                if files:
                    success.append(f"Static files collected ({len(files)} files)")
                else:
                    warnings.append("Static root exists but is empty - run collectstatic")
            else:
                warnings.append(f"Static root {static_root} does not exist - run collectstatic")
        else:
            warnings.append("STATIC_ROOT not configured")

        # Check migrations
        try:
            from django.db.migrations.executor import MigrationExecutor
            executor = MigrationExecutor(connection)
            plan = executor.migration_plan(executor.loader.graph.leaf_nodes())
            if plan:
                warnings.append(f"{len(plan)} pending migrations need to be applied")
            else:
                success.append("All migrations are up to date")
        except Exception as e:
            warnings.append(f"Cannot check migrations: {e}")

        # Check ALLOWED_HOSTS
        allowed = settings.ALLOWED_HOSTS
        if allowed and len(allowed) > 0 and allowed != ["*"]:
            success.append(f"ALLOWED_HOSTS={allowed}")
        elif allowed == ["*"]:
            warnings.append("ALLOWED_HOSTS is ['*'] - restrict in production")
        else:
            warnings.append("ALLOWED_HOSTS is empty or not set")

        # Check CORS config
        if hasattr(settings, "CORS_ALLOWED_ORIGINS") and settings.CORS_ALLOWED_ORIGINS:
            success.append(f"CORS_ALLOWED_ORIGINS={settings.CORS_ALLOWED_ORIGINS}")
        else:
            warnings.append("CORS_ALLOWED_ORIGINS not configured")

        # Check email config
        email_backend = getattr(settings, "EMAIL_BACKEND", "")
        if "console" in email_backend:
            warnings.append("EMAIL_BACKEND is console - emails will not be sent")
        elif "smtp" in email_backend:
            if getattr(settings, "EMAIL_HOST", ""):
                success.append("SMTP email configured")
            else:
                warnings.append("SMTP email backend selected but EMAIL_HOST is empty")

        # Check security settings for production
        secure_ssl = getattr(settings, "SESSION_COOKIE_SECURE", False)
        csrf_secure = getattr(settings, "CSRF_COOKIE_SECURE", False)
        if secure_ssl and csrf_secure:
            success.append("Secure cookies configured")
        else:
            warnings.append("SESSION_COOKIE_SECURE or CSRF_COOKIE_SECURE not set")

        # Report
        self.stdout.write("\n" + "=" * 60)
        self.stdout.write("DEPLOYMENT VALIDATION REPORT")
        self.stdout.write("=" * 60)

        if success:
            self.stdout.write(self.style.SUCCESS("\n✓ Passed:"))
            for msg in success:
                self.stdout.write(f"  ✓ {msg}")

        if warnings:
            self.stdout.write(self.style.WARNING("\n⚠ Warnings:"))
            for msg in warnings:
                self.stdout.write(f"  ⚠ {msg}")

        if errors:
            self.stdout.write(self.style.ERROR("\n✗ Errors:"))
            for msg in errors:
                self.stdout.write(f"  ✗ {msg}")

        self.stdout.write("\n" + "=" * 60)
        total = len(success) + len(warnings) + len(errors)
        score = round((len(success) / total * 100)) if total else 0
        self.stdout.write(f"Score: {score}% ({len(success)}/{total} checks passed)")
        self.stdout.write("=" * 60)

        if errors:
            sys.exit(1)
