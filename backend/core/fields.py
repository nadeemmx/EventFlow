import os
import base64
import logging

from django.db import models
from django.conf import settings

logger = logging.getLogger("security")

# Encrypted values are prefixed to distinguish from legacy signed values
_ENCRYPTED_PREFIX = "enc:v1:"


def _get_encryption_key():
    from django.conf import settings
    key_b64 = getattr(settings, "ENCRYPTION_KEY", "") or os.environ.get("ENCRYPTION_KEY", "")
    if not key_b64:
        raise ValueError(
            "ENCRYPTION_KEY setting or environment variable is required for "
            "EncryptedTextField. Generate one with: "
            "python -c \"import secrets,base64;print(base64.b64encode(secrets.token_bytes(32)).decode())\""
        )
    key = base64.b64decode(key_b64)
    if len(key) != 32:
        raise ValueError(
            "ENCRYPTION_KEY must decode to exactly 32 bytes (256 bits). "
            "Generate a valid key with: "
            "python -c \"import secrets,base64;print(base64.b64encode(secrets.token_bytes(32)).decode())\""
        )
    return key


def _encrypt_value(plaintext):
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM
    key = _get_encryption_key()
    aesgcm = AESGCM(key)
    nonce = os.urandom(12)  # 96-bit nonce for AES-GCM
    ciphertext = aesgcm.encrypt(nonce, plaintext.encode("utf-8"), None)
    return _ENCRYPTED_PREFIX + base64.b64encode(nonce + ciphertext).decode("ascii")


def _decrypt_value(token):
    raw = base64.b64decode(token)
    if len(raw) < 12 + 16:
        raise ValueError("Ciphertext too short")
    nonce = raw[:12]
    ciphertext = raw[12:]
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM
    key = _get_encryption_key()
    aesgcm = AESGCM(key)
    plaintext = aesgcm.decrypt(nonce, ciphertext, None)
    return plaintext.decode("utf-8")


class EncryptedTextField(models.TextField):
    """
    Encrypted text field using AES-256-GCM authenticated encryption.

    Values are encrypted at rest in the database. The encryption key
    must be provided via the ENCRYPTION_KEY environment variable.

    Backward compatibility: legacy values signed with Django's signing
    module are transparently decrypted on read. New writes always use
    AES-GCM encryption. A data migration should be run to re-encrypt
    all legacy values.
    """

    def get_internal_type(self):
        return "TextField"

    def from_db_value(self, value, expression, connection):
        if value is None:
            return value
        if not isinstance(value, str):
            return value
        # New AES-GCM encrypted values
        if value.startswith(_ENCRYPTED_PREFIX):
            try:
                return _decrypt_value(value[len(_ENCRYPTED_PREFIX):])
            except Exception:
                logger.error("Failed to decrypt AES-GCM value from database")
                return value
        # Legacy signed values — fall back to signing.loads for backward compat
        try:
            from django.core import signing
            return signing.loads(value)
        except Exception:
            logger.warning("Failed to decrypt legacy signed value from database")
            return value

    def to_python(self, value):
        if value is None or not isinstance(value, str):
            return value
        # Already encrypted with AES-GCM
        if value.startswith(_ENCRYPTED_PREFIX):
            try:
                return _decrypt_value(value[len(_ENCRYPTED_PREFIX):])
            except Exception:
                return value
        # Legacy signed values
        try:
            from django.core import signing
            return signing.loads(value)
        except Exception:
            return value

    def get_prep_value(self, value):
        if value is None:
            return None
        return _encrypt_value(str(value))

    def get_db_prep_save(self, value, connection):
        if value is None:
            return None
        return _encrypt_value(str(value))
