from abc import ABC, abstractmethod


class PaymentGatewayProvider(ABC):
    @abstractmethod
    def create_payment(self, amount, currency, description, metadata=None):
        pass

    @abstractmethod
    def process_refund(self, transaction_id, amount):
        pass

    @abstractmethod
    def verify_payment(self, transaction_id):
        pass


class ManualPaymentGateway(PaymentGatewayProvider):
    def create_payment(self, amount, currency, description, metadata=None):
        return {"status": "pending", "message": "Manual payment recorded"}

    def process_refund(self, transaction_id, amount):
        return {"status": "refunded", "message": "Manual refund processed"}

    def verify_payment(self, transaction_id):
        return {"status": "verified", "message": "Manual verification"}
