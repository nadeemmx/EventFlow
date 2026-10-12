import re
import magic
from django.core.exceptions import ValidationError


def validate_mobile(value):
    # Mirrors the frontend zod rule (frontend/app/(dashboard)/customers/new/
    # page.tsx:24). The UI submits the number as typed — spaces, dashes and
    # parentheses included, with no normalisation — so the backend must accept
    # at least everything the UI accepts, or users get a 400 for input their
    # own form called valid. This validator existed but was wired to nothing,
    # which is how "mobile": "not-a-number-mgr" reached the database
    # (QA-TEST-REPORT-ROLES.md F-5).
    if not re.match(r"^[0-9+\-\s()]{7,15}$", value):
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
    if not re.search(r"[!@#$%^&*(),.?\":{}|<>\-_=+\[\]\\;'/`~]", value):
        raise ValidationError("Password must contain at least one special character.")


ALLOWED_IMAGE_EXTENSIONS = {"jpg", "jpeg", "png", "webp", "gif"}
ALLOWED_IMAGE_MIMES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
MAX_IMAGE_SIZE_MB = 10

ALLOWED_PDF_EXTENSIONS = {"pdf"}
ALLOWED_PDF_MIMES = {"application/pdf"}
MAX_PDF_SIZE_MB = 20


def _validate_file(file, allowed_extensions, allowed_mimes, max_size_mb, label):
    if not file:
        return

    ext = ""
    if hasattr(file, "name") and file.name:
        ext = file.name.rsplit(".", 1)[-1].lower() if "." in file.name else ""

    if ext not in allowed_extensions:
        raise ValidationError(
            f"Invalid file type '.{ext}' for {label}. "
            f"Allowed: {', '.join(sorted(allowed_extensions))}"
        )

    file.seek(0)
    chunk = file.read(2048)
    file.seek(0)

    try:
        detected_mime = magic.from_buffer(chunk, mime=True)
    except Exception:
        detected_mime = None

    if detected_mime and detected_mime not in allowed_mimes:
        raise ValidationError(
            f"File content does not match expected type for {label}. "
            f"Detected: {detected_mime}"
        )

    file.seek(0, 2)
    size_bytes = file.tell()
    file.seek(0)

    max_bytes = max_size_mb * 1024 * 1024
    if size_bytes > max_bytes:
        raise ValidationError(
            f"File too large ({size_bytes // (1024 * 1024)}MB). "
            f"Maximum allowed: {max_size_mb}MB."
        )


def validate_image_file(file):
    _validate_file(file, ALLOWED_IMAGE_EXTENSIONS, ALLOWED_IMAGE_MIMES, MAX_IMAGE_SIZE_MB, "image")


def validate_pdf_file(file):
    _validate_file(file, ALLOWED_PDF_EXTENSIONS, ALLOWED_PDF_MIMES, MAX_PDF_SIZE_MB, "PDF")
