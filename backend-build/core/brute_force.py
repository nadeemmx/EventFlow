import time
from django.core.cache import cache


class BruteForceProtection:
    MAX_ATTEMPTS = 5
    LOCKOUT_DURATION = 900
    ATTEMPT_WINDOW = 300

    @staticmethod
    def record_failed_attempt(email, ip_address):
        key = f"login_attempts:{email}:{ip_address}"
        attempts = cache.get(key, [])
        now = time.time()
        attempts = [t for t in attempts if now - t < BruteForceProtection.ATTEMPT_WINDOW]
        attempts.append(now)
        cache.set(key, attempts, BruteForceProtection.ATTEMPT_WINDOW)

    @staticmethod
    def is_locked_out(email, ip_address):
        key = f"login_lockout:{email}"
        locked_until = cache.get(key, 0)
        if time.time() < locked_until:
            return True
        attempt_key = f"login_attempts:{email}:{ip_address}"
        attempts = cache.get(attempt_key, [])
        now = time.time()
        attempts = [t for t in attempts if now - t < BruteForceProtection.ATTEMPT_WINDOW]
        if len(attempts) >= BruteForceProtection.MAX_ATTEMPTS:
            cache.set(key, time.time() + BruteForceProtection.LOCKOUT_DURATION, BruteForceProtection.LOCKOUT_DURATION)
            cache.delete(attempt_key)
            return True
        return False

    @staticmethod
    def clear_attempts(email, ip_address):
        cache.delete(f"login_attempts:{email}:{ip_address}")
        cache.delete(f"login_lockout:{email}")
