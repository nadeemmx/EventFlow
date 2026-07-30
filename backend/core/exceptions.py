from rest_framework.views import exception_handler
from rest_framework.response import Response


class DomainException(Exception):
    def __init__(self, message="Domain error", code=None, details=None):
        self.message = message
        self.code = code
        self.details = details or {}
        super().__init__(self.message)


class ValidationException(DomainException):
    pass


class PermissionDeniedException(DomainException):
    pass


class NotFoundException(DomainException):
    pass


class ConflictException(DomainException):
    pass


class TenantMismatchException(PermissionDeniedException):
    pass


class SubscriptionLimitException(DomainException):
    pass


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
