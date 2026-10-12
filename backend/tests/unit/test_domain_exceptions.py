import pytest
from core.exceptions import (
    ConflictException,
    DomainException,
    NotFoundException,
    PermissionDeniedException,
    SubscriptionLimitException,
    TenantMismatchException,
    ValidationException,
    custom_exception_handler,
)


STATUS_CASES = [
    (ValidationException, 400),
    (PermissionDeniedException, 403),
    (TenantMismatchException, 403),
    (NotFoundException, 404),
    (ConflictException, 409),
    (SubscriptionLimitException, 402),
]


class TestDomainExceptionStatusCodes:
    @pytest.mark.parametrize("exc_cls,expected", STATUS_CASES)
    def test_status_code_attribute(self, exc_cls, expected):
        assert exc_cls("boom").status_code == expected

    @pytest.mark.parametrize("exc_cls,expected", STATUS_CASES)
    def test_exception_handler_uses_status_code(self, exc_cls, expected):
        response = custom_exception_handler(exc_cls("boom"), context={})
        assert response is not None
        assert response.status_code == expected
        assert response.data["message"] == "boom"
        assert response.data["success"] is False

    def test_generic_domain_exception_defaults_to_400(self):
        response = custom_exception_handler(DomainException("plain"), context={})
        assert response.status_code == 400

    def test_unrelated_exception_passes_through_unchanged(self):
        assert custom_exception_handler(ValueError("nope"), context={}) is None
