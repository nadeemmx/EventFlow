import os
import base64
import pytest
from core.fields import EncryptedTextField, _ENCRYPTED_PREFIX, _encrypt_value, _decrypt_value


class TestEncryptedTextField:
    def setup_method(self):
        # Set a test encryption key
        if not os.environ.get("ENCRYPTION_KEY"):
            os.environ["ENCRYPTION_KEY"] = base64.b64encode(b"test-key-32-bytes-long-for-aes256").decode()

    def test_encrypts_decrypts_value(self):
        field = EncryptedTextField()
        original = "sk_test_abcdef123456"
        prepared = field.get_prep_value(original)
        assert prepared != original
        assert isinstance(prepared, str)
        assert prepared.startswith(_ENCRYPTED_PREFIX)
        restored = field.from_db_value(prepared, None, None)
        assert restored == original

    def test_handles_none(self):
        field = EncryptedTextField()
        assert field.get_prep_value(None) is None
        assert field.from_db_value(None, None, None) is None

    def test_handles_empty_string(self):
        field = EncryptedTextField()
        prepared = field.get_prep_value("")
        assert prepared is not None
        restored = field.from_db_value(prepared, None, None)
        assert restored == ""

    def test_returns_plaintext_if_not_signed(self):
        field = EncryptedTextField()
        result = field.from_db_value("plaintext_value", None, None)
        assert result == "plaintext_value"

    def test_to_python_decrypts(self):
        field = EncryptedTextField()
        encrypted = _encrypt_value("secret_key_123")
        result = field.to_python(encrypted)
        assert result == "secret_key_123"

    def test_db_prep_save_encrypts(self):
        field = EncryptedTextField()
        result = field.get_db_prep_save("sensitive_data", connection=None)
        assert result != "sensitive_data"
        assert result.startswith(_ENCRYPTED_PREFIX)
        # Verify it can be decrypted back
        decrypted = _decrypt_value(result[len(_ENCRYPTED_PREFIX):])
        assert decrypted == "sensitive_data"

    def test_unique_nonces(self):
        """Each encryption produces a different ciphertext (random nonce)."""
        val1 = _encrypt_value("same_value")
        val2 = _encrypt_value("same_value")
        assert val1 != val2
        # But both decrypt to the same value
        assert _decrypt_value(val1[len(_ENCRYPTED_PREFIX):]) == "same_value"
        assert _decrypt_value(val2[len(_ENCRYPTED_PREFIX):]) == "same_value"

    def test_backward_compat_with_signing(self):
        """Legacy signed values are still readable."""
        from django.core import signing
        field = EncryptedTextField()
        signed_value = signing.dumps("legacy_secret", compress=True)
        result = field.from_db_value(signed_value, None, None)
        assert result == "legacy_secret"

    def test_invalid_ciphertext_returns_raw(self):
        """Corrupted ciphertext returns the raw value (graceful degradation)."""
        field = EncryptedTextField()
        result = field.from_db_value("enc:v1:invalid_base64_data", None, None)
        assert result == "enc:v1:invalid_base64_data"

    def test_requires_encryption_key(self):
        """Missing ENCRYPTION_KEY raises ValueError."""
        from django.conf import settings
        old_env = os.environ.pop("ENCRYPTION_KEY", None)
        old_setting = getattr(settings, "ENCRYPTION_KEY", None)
        settings.ENCRYPTION_KEY = ""
        try:
            with pytest.raises(ValueError, match="ENCRYPTION_KEY"):
                _encrypt_value("test")
        finally:
            if old_env:
                os.environ["ENCRYPTION_KEY"] = old_env
            if old_setting:
                settings.ENCRYPTION_KEY = old_setting
