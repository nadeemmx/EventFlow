"""
Management command to re-encrypt legacy signed values to AES-256-GCM.

Run this after setting the ENCRYPTION_KEY environment variable
to migrate existing signed data to encrypted data.

Usage:
    python manage.py reencrypt_fields --dry-run   # Preview changes
    python manage.py reencrypt_fields              # Apply changes
    python manage.py reencrypt_fields --model apps.settings.models.PaymentGatewaySettings  # Specific model
"""
import os
import sys
import logging

from django.core.management.base import BaseCommand
from django.core import signing

from core.fields import _ENCRYPTED_PREFIX, _encrypt_value

logger = logging.getLogger("security")


class Command(BaseCommand):
    help = "Re-encrypt legacy signed EncryptedTextField values to AES-256-GCM"

    def add_arguments(self, parser):
        parser.add_argument(
            "--dry-run", action="store_true",
            help="Show what would be changed without making changes",
        )
        parser.add_argument(
            "--model", type=str, default="",
            help="Only re-encrypt a specific model (dotted path)",
        )

    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        target_model = options["model"]

        if not os.environ.get("ENCRYPTION_KEY"):
            self.stderr.write(
                "ERROR: ENCRYPTION_KEY environment variable is not set. "
                "Set it before running this command."
            )
            sys.exit(1)

        from apps.settings.models import (
            PaymentGatewaySettings, WhatsAppSettings, EmailSettings,
        )

        encrypted_models = [
            (PaymentGatewaySettings, ["api_key", "api_secret", "webhook_secret"]),
            (WhatsAppSettings, ["api_key", "phone_number_id", "business_account_id", "webhook_verify_token"]),
            (EmailSettings, ["smtp_password"]),
        ]

        total_reencrypted = 0
        total_errors = 0

        for model, fields in encrypted_models:
            if target_model and target_model != f"{model.__module__}.{model.__name__}":
                continue

            self.stdout.write(f"\nProcessing {model.__name__}...")

            for instance in model.objects.all():
                changed = False
                for field_name in fields:
                    raw_value = getattr(instance, field_name)
                    if not raw_value or not isinstance(raw_value, str):
                        continue
                    if raw_value.startswith(_ENCRYPTED_PREFIX):
                        continue
                    # This is a legacy signed value — re-encrypt it
                    try:
                        plaintext = signing.loads(raw_value)
                        encrypted = _encrypt_value(plaintext)
                        if dry_run:
                            self.stdout.write(
                                f"  Would re-encrypt {model.__name__}#{instance.pk}.{field_name}"
                            )
                        else:
                            # Direct DB update to avoid triggering field methods
                            model.objects.filter(pk=instance.pk).update(**{field_name: encrypted})
                        changed = True
                        total_reencrypted += 1
                    except Exception as e:
                        self.stderr.write(
                            f"  ERROR: Could not re-encrypt {model.__name__}#{instance.pk}.{field_name}: {e}"
                        )
                        total_errors += 1

                if changed and not dry_run:
                    self.stdout.write(f"  Re-encrypted {model.__name__}#{instance.pk}")

        prefix = "Would re-encrypt" if dry_run else "Re-encrypted"
        self.stdout.write(
            self.style.SUCCESS(f"\n{prefix} {total_reencrypted} field(s), {total_errors} error(s)")
        )

        if dry_run:
            self.stdout.write(self.style.WARNING("Dry run — no changes were made."))
