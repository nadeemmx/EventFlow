import pytest
from django.core.exceptions import ValidationError
from core.validators import validate_mobile, validate_gst, validate_password_strength


class TestValidators:
    def test_valid_mobile(self):
        validate_mobile("+919876543210")

    def test_invalid_mobile(self):
        with pytest.raises(ValidationError):
            validate_mobile("123")

    def test_valid_gst(self):
        validate_gst("27ABCDE1234F1Z5")

    def test_invalid_gst(self):
        with pytest.raises(ValidationError):
            validate_gst("invalid")

    def test_strong_password(self):
        validate_password_strength("Password123!")

    def test_weak_password(self):
        with pytest.raises(ValidationError):
            validate_password_strength("weak")

    def test_password_missing_special_char(self):
        with pytest.raises(ValidationError, match="special character"):
            validate_password_strength("Password123")
