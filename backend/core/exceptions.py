from rest_framework.views import exception_handler
from rest_framework.response import Response


class DomainException(Exception):
    # Consumed by custom_exception_handler via getattr(exc, "status_code", 400).
    status_code = 400

    def __init__(self, message="Domain error", code=None, details=None):
        self.message = message
        self.code = code
        self.details = details or {}
        super().__init__(self.message)


class ValidationException(DomainException):
    status_code = 400


class PermissionDeniedException(DomainException):
    status_code = 403


class NotFoundException(DomainException):
    status_code = 404


class ConflictException(DomainException):
    status_code = 409


class TenantMismatchException(PermissionDeniedException):
    status_code = 403


class SubscriptionLimitException(DomainException):
    status_code = 402


def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None:
        errors = response.data
        if isinstance(errors, dict) and "detail" in errors:
            message = str(errors["detail"])
            errors = {}
        else:
            message = "Validation failed"
        return Response(
            {"success": False, "message": message, "errors": errors},
            status=response.status_code,
        )
    if isinstance(exc, DomainException):
        return Response(
            {"success": False, "message": exc.message, "errors": exc.details},
            status=getattr(exc, "status_code", 400),
        )
    return response
