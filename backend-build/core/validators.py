import re
from django.core.exceptions import ValidationError


def validate_mobile(value):
    if not re.match(r"^\+?[1-9]\d{9,14}$", value):
        raise ValidationError("Enter a valid mobile number.")


def validate_gst(value):
    if value and not re.match(r"^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$", value):
        raise ValidationError("Enter a valid GST number.")


def validate_password_strength(value):
    if len(value) < 8:
        raise ValidationError("Password must be at least 8 characters.")
    if not re.search(r"[A-Z]", value):
        raise ValidationError("Password must contain at least one uppercase letter.")
    if not re.search(r"[a-z]", value):
        raise ValidationError("Password must contain at least one lowercase letter.")
    if not re.search(r"[0-9]", value):
        raise ValidationError("Password must contain at least one number.")
