import time
import logging
import threading
from django.core.cache import cache
from django.conf import settings

logger = logging.getLogger("security")

_local_lock = threading.Lock()
_local_attempts = {}
_local_lockouts = {}


def _is_production():
    return getattr(settings, "DEBUG", False) is False


def _cache_get(key, default=None):
    try:
        return cache.get(key, default)
    except Exception:
        if _is_production():
            logger.critical(
                "CACHE_UNAVAILABLE: Redis unreachable for key=%s. "
                "Brute-force protection is DEGRADED — not shared across "
                "workers. Immediate Redis recovery required.",
                key,
            )
        else:
            logger.warning(
                "CACHE_UNAVAILABLE: Using local memory fallback for key=%s "
                "(development only).",
                key,
            )
        return default


def _cache_set(key, value, timeout=None):
    try:
        cache.set(key, value, timeout)
    except Exception:
        if _is_production():
            logger.critical(
                "CACHE_UNAVAILABLE: Redis unreachable for set key=%s. "
                "Brute-force protection is DEGRADED.",
                key,
            )
        else:
            logger.warning(
                "CACHE_UNAVAILABLE: Using local memory fallback for set key=%s "
                "(development only).",
                key,
            )


def _cache_delete(key):
    try:
        cache.delete(key)
    except Exception:
        if _is_production():
            logger.critical(
                "CACHE_UNAVAILABLE: Redis unreachable for delete key=%s. "
                "Brute-force protection is DEGRADED.",
                key,
            )
        else:
            logger.warning(
                "CACHE_UNAVAILABLE: Using local memory fallback for delete key=%s "
                "(development only).",
                key,
            )


class BruteForceProtection:
    MAX_ATTEMPTS = 5
    LOCKOUT_DURATION = 900
    ATTEMPT_WINDOW = 300

    @staticmethod
    def record_failed_attempt(email, ip_address):
        key = f"login_attempts:{email}:{ip_address}"
        attempts = _cache_get(key, [])
        now = time.time()
        attempts = [t for t in attempts if now - t < BruteForceProtection.ATTEMPT_WINDOW]
        attempts.append(now)
        _cache_set(key, attempts, BruteForceProtection.ATTEMPT_WINDOW)

    @staticmethod
    def is_locked_out(email, ip_address):
        lockout_key = f"login_lockout:{email}"
        locked_until = _cache_get(lockout_key, 0)
        if time.time() < locked_until:
            return True
        attempt_key = f"login_attempts:{email}:{ip_address}"
        attempts = _cache_get(attempt_key, [])
        now = time.time()
        attempts = [t for t in attempts if now - t < BruteForceProtection.ATTEMPT_WINDOW]
        if len(attempts) >= BruteForceProtection.MAX_ATTEMPTS:
            _cache_set(
                lockout_key,
                time.time() + BruteForceProtection.LOCKOUT_DURATION,
                BruteForceProtection.LOCKOUT_DURATION,
            )
            _cache_delete(attempt_key)
            return True
        return False

    @staticmethod
    def clear_attempts(email, ip_address):
        _cache_delete(f"login_attempts:{email}:{ip_address}")
        _cache_delete(f"login_lockout:{email}")
