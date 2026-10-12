from .base import *
import base64, secrets

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": ":memory:",
    }
}
PASSWORD_HASHERS = ["django.contrib.auth.hashers.MD5PasswordHasher"]

# Test encryption key (32 bytes, AES-256-GCM)
ENCRYPTION_KEY = base64.b64encode(secrets.token_bytes(32)).decode()

LOGGING = {
    "version": 1,
    "disable_existing_loggers": True,
}

REST_FRAMEWORK = REST_FRAMEWORK.copy()
REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"] = {
    "anon": "10000/minute",
    "login": "10000/minute",
    "forgot_password": "10000/minute",
    "user": "10000/minute",
    "password_reset": "10000/minute",
    "token_refresh": "10000/minute",
    "password_change": "10000/minute",
    "privacy_request": "10000/minute",
    "contact": "10000/minute",
}

CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
    }
}
