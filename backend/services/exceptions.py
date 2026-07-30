from core.exceptions import DomainException


class BookingConflictException(DomainException):
    pass


class PaymentExceedsBalanceException(DomainException):
    pass


class SubscriptionExpiredException(DomainException):
    pass


class VenueNotAvailableException(DomainException):
    pass


class LimitExceededException(DomainException):
    pass
