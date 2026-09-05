from .base import *
import os
import sys

DEBUG = False

# SECRET_KEY is REQUIRED and must not be the insecure default
if not config("DJANGO_SECRET_KEY", default="") or SECRET_KEY.startswith("insecure"):
    raise ValueError(
        "DJANGO_SECRET_KEY environment variable is required in production. "
        "Generate one with: python -c \"import secrets;print(secrets.token_urlsafe(50))\""
    )

ALLOWED_HOSTS = config(
    "DJANGO_ALLOWED_HOSTS",
    default=".eventflow.com,api.eventflow.com",
    cast=Csv(),
)
STATIC_ROOT = BASE_DIR / "staticfiles"

# CSRF trusted origins for the frontend domain
CSRF_TRUSTED_ORIGINS = config(
    "CSRF_TRUSTED_ORIGINS",
    default="https://app.eventflow.com,https://api.eventflow.com",
    cast=Csv(),
)

# Redis is REQUIRED in production for shared brute-force protection and throttling
if not REDIS_URL:
    raise ValueError(
        "REDIS_URL environment variable is required in production. "
        "Brute-force protection and throttling depend on a shared cache "
        "across Gunicorn workers. Set REDIS_URL=redis://127.0.0.1:6379/0 "
        "or equivalent in your environment."
    )

# Encryption key is REQUIRED for EncryptedTextField (AES-256-GCM)
if not config("ENCRYPTION_KEY", default=""):
    raise ValueError(
        "ENCRYPTION_KEY environment variable is required in production. "
        "EncryptedTextField uses AES-256-GCM for encryption at rest. "
        "Generate a key with: "
        "python -c \"import secrets,base64;print(base64.b64encode(secrets.token_bytes(32)).decode())\""
    )

# Database connection persistence (reuse connections across requests)
DATABASES["default"]["CONN_MAX_AGE"] = 600

# Security hardening
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = "Lax"
CSRF_COOKIE_SECURE = True
CSRF_COOKIE_HTTPONLY = True
CSRF_COOKIE_SAMESITE = "Lax"
SECURE_SSL_REDIRECT = False  # handled by web server
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = "DENY"

# Email - console fallback if SMTP unconfigured
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"
if config("EMAIL_HOST", default=""):
    EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
    EMAIL_HOST = config("EMAIL_HOST")
    EMAIL_PORT = config("EMAIL_PORT", default=587, cast=int)
    EMAIL_HOST_USER = config("EMAIL_HOST_USER", default="")
    EMAIL_HOST_PASSWORD = config("EMAIL_HOST_PASSWORD", default="")
    EMAIL_USE_TLS = config("EMAIL_USE_TLS", default=True, cast=bool)
    DEFAULT_FROM_EMAIL = config("DEFAULT_FROM_EMAIL", default="noreply@eventflow.com")

# File upload size limit
DATA_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024  # 10MB

# Django file storage - local (no S3)
DEFAULT_FILE_STORAGE = "django.core.files.storage.FileSystemStorage"

# WhiteNoise for static files in production
INSTALLED_APPS = ["whitenoise.runserver_nostatic"] + INSTALLED_APPS + ["whitenoise"]
MIDDLEWARE = [m for m in MIDDLEWARE]
MIDDLEWARE.insert(1, "whitenoise.middleware.WhiteNoiseMiddleware")
STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"

# Ensure logs directory exists
LOGS_DIR = BASE_DIR / "logs"
LOGS_DIR.mkdir(exist_ok=True)

# Structured logging
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "{levelname} {asctime} {module} {message}",
            "style": "{",
        },
    },
    "handlers": {
        "console": {
            "level": "INFO",
            "class": "logging.StreamHandler",
            "formatter": "verbose",
        },
        "file": {
            "level": "WARNING",
            "class": "logging.handlers.RotatingFileHandler",
            "filename": BASE_DIR / "logs" / "django.log",
            "formatter": "verbose",
            "maxBytes": 10 * 1024 * 1024,
            "backupCount": 5,
        },
    },
    "loggers": {
        "django": {
            "handlers": ["console", "file"],
            "level": "INFO",
            "propagate": False,
        },
        "api": {
            "handlers": ["console", "file"],
            "level": "INFO",
            "propagate": False,
        },
        "security": {
            "handlers": ["console", "file"],
            "level": "INFO",
            "propagate": False,
        },
        "authentication": {
            "handlers": ["console", "file"],
            "level": "INFO",
            "propagate": False,
        },
    },
    "root": {
        "handlers": ["console", "file"],
        "level": "WARNING",
    },
}
