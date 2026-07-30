class PaymentGatewayError(Exception):
    pass


class PaymentDeclinedError(PaymentGatewayError):
    pass


class RefundFailedError(PaymentGatewayError):
    pass
