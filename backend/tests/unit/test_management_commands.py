import pytest
from django.core.management import call_command
from django.test import TestCase


class TestManagementCommands(TestCase):
    def test_send_notifications_command_runs(self):
        result = call_command("send_notifications", "--limit=5")
        assert result is None

    def test_send_emails_command_runs(self):
        result = call_command("send_emails", "--limit=5")
        assert result is None

    def test_cleanup_expired_tokens_command_runs(self):
        result = call_command("cleanup_expired_tokens")
        assert result is None

    def test_generate_scheduled_reports_command_runs(self):
        result = call_command("generate_scheduled_reports", "--frequency=daily")
        assert result is None
