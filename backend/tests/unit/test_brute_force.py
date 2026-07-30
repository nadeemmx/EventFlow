import time
import pytest
from unittest.mock import patch, MagicMock
from core.brute_force import BruteForceProtection


class TestBruteForceProtection:
    def test_initial_not_locked_out(self):
        assert BruteForceProtection.is_locked_out("test@example.com", "127.0.0.1") is False

    def test_lockout_after_max_attempts(self):
        for _ in range(BruteForceProtection.MAX_ATTEMPTS - 1):
            BruteForceProtection.record_failed_attempt("test@example.com", "127.0.0.1")
        assert BruteForceProtection.is_locked_out("test@example.com", "127.0.0.1") is False
        BruteForceProtection.record_failed_attempt("test@example.com", "127.0.0.1")
        assert BruteForceProtection.is_locked_out("test@example.com", "127.0.0.1") is True

    def test_clear_attempts(self):
        for _ in range(BruteForceProtection.MAX_ATTEMPTS + 1):
            BruteForceProtection.record_failed_attempt("clear@test.com", "127.0.0.1")
        BruteForceProtection.clear_attempts("clear@test.com", "127.0.0.1")
        assert BruteForceProtection.is_locked_out("clear@test.com", "127.0.0.1") is False

    def test_different_email_not_locked(self):
        for _ in range(BruteForceProtection.MAX_ATTEMPTS + 1):
            BruteForceProtection.record_failed_attempt("locked@example.com", "127.0.0.1")
        assert BruteForceProtection.is_locked_out("other@example.com", "127.0.0.1") is False
