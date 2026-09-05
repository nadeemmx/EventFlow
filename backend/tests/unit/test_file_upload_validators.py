import io
import pytest
from django.core.exceptions import ValidationError
from django.core.files.uploadedfile import SimpleUploadedFile
from unittest.mock import patch, MagicMock
from core.validators import (
    validate_image_file, validate_pdf_file,
    ALLOWED_IMAGE_EXTENSIONS, ALLOWED_PDF_EXTENSIONS,
)


class TestImageUploadValidation:
    def _make_image(self, name="test.jpg", content=b"\xff\xd8\xff\xe0" + b"\x00" * 100):
        return SimpleUploadedFile(name, content, content_type="image/jpeg")

    def test_valid_jpg_accepted(self):
        f = self._make_image("photo.jpg", b"\xff\xd8\xff\xe0" + b"\x00" * 100)
        validate_image_file(f)

    def test_valid_png_accepted(self):
        png_header = b"\x89PNG\r\n\x1a\n" + b"\x00" * 100
        f = SimpleUploadedFile("photo.png", png_header, content_type="image/png")
        with patch("core.validators.magic.from_buffer", return_value="image/png"):
            validate_image_file(f)

    def test_invalid_exe_rejected(self):
        f = SimpleUploadedFile("malware.exe", b"MZ\x90\x00" + b"\x00" * 100, content_type="application/x-executable")
        with pytest.raises(ValidationError, match="Invalid file type"):
            validate_image_file(f)

    def test_invalid_html_rejected(self):
        f = SimpleUploadedFile("page.html", b"<html>" + b"\x00" * 100, content_type="text/html")
        with pytest.raises(ValidationError, match="Invalid file type"):
            validate_image_file(f)

    def test_empty_file_accepted(self):
        validate_image_file(None)
        validate_image_file("")

    def test_file_too_large_rejected(self):
        large_content = b"\xff\xd8\xff\xe0" + b"\x00" * (11 * 1024 * 1024)
        f = SimpleUploadedFile("huge.jpg", large_content, content_type="image/jpeg")
        with pytest.raises(ValidationError, match="File too large"):
            validate_image_file(f)

    @patch("core.validators.magic")
    def test_spoofed_extension_rejected(self, mock_magic):
        mock_magic.from_buffer.return_value = "application/x-executable"
        f = SimpleUploadedFile("image.jpg", b"\xff\xd8\xff\xe0" + b"\x00" * 100, content_type="image/jpeg")
        with pytest.raises(ValidationError, match="does not match"):
            validate_image_file(f)


class TestPDFUploadValidation:
    def _make_pdf(self, name="doc.pdf", content=b"%PDF-1.4" + b"\x00" * 100):
        return SimpleUploadedFile(name, content, content_type="application/pdf")

    def test_valid_pdf_accepted(self):
        f = self._make_pdf()
        validate_pdf_file(f)

    def test_invalid_zip_rejected(self):
        f = SimpleUploadedFile("archive.zip", b"PK\x03\x04" + b"\x00" * 100, content_type="application/zip")
        with pytest.raises(ValidationError, match="Invalid file type"):
            validate_pdf_file(f)

    def test_empty_file_accepted(self):
        validate_pdf_file(None)
        validate_pdf_file("")

    def test_file_too_large_rejected(self):
        large_content = b"%PDF-1.4" + b"\x00" * (21 * 1024 * 1024)
        f = SimpleUploadedFile("huge.pdf", large_content, content_type="application/pdf")
        with pytest.raises(ValidationError, match="File too large"):
            validate_pdf_file(f)

    @patch("core.validators.magic")
    def test_spoofed_pdf_rejected(self, mock_magic):
        mock_magic.from_buffer.return_value = "application/x-executable"
        f = self._make_pdf()
        with pytest.raises(ValidationError, match="does not match"):
            validate_pdf_file(f)
