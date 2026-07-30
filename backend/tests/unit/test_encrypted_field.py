import pytest
from django.core import signing
from core.fields import EncryptedTextField


class TestEncryptedTextField:
    def test_encrypts_decrypts_value(self):
        field = EncryptedTextField()
        original = "sk_test_abcdef123456"
        prepared = field.get_prep_value(original)
        assert prepared != original
        assert isinstance(prepared, str)
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

    def test_to_python_unsigns(self):
        field = EncryptedTextField()
        signed = signing.dumps("secret_key_123", compress=True)
        result = field.to_python(signed)
        assert result == "secret_key_123"

    def test_db_prep_save_encrypts(self):
        field = EncryptedTextField()
        result = field.get_db_prep_save("sensitive_data", connection=None)
        assert result != "sensitive_data"
        assert signing.loads(result) == "sensitive_data"
