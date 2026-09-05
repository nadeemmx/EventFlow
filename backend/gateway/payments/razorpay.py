import logging
import hashlib
import hmac
from decimal import Decimal
from gateway.payments.base import PaymentGatewayProvider
from gateway.payments.exceptions import PaymentGatewayError, PaymentDeclinedError, RefundFailedError

logger = logging.getLogger(__name__)


class RazorpayGateway(PaymentGatewayProvider):
    def __init__(self, api_key, api_secret):
        self.api_key = api_key
        self.api_secret = api_secret
        self._client = None

    @property
    def client(self):
        if self._client is None:
            import razorpay
            self._client = razorpay.Client(auth=(self.api_key, self.api_secret))
        return self._client

    def create_payment(self, amount, currency="INR", description="", metadata=None):
        try:
            amount_paise = int(Decimal(str(amount)) * 100)
            order_data = {
                "amount": amount_paise,
                "currency": currency,
                "receipt": description[:40] if description else "",
            }
            if metadata:
                order_data["notes"] = metadata
            order = self.client.order.create(data=order_data)
            logger.info("Razorpay order created: %s", order.get("id"))
            return {
                "success": True,
                "order_id": order["id"],
                "amount": amount_paise,
                "currency": currency,
                "key_id": self.api_key,
                "status": order["status"],
            }
        except Exception as e:
            logger.error("Razorpay order creation failed: %s", e)
            raise PaymentGatewayError(str(e))

    def verify_payment(self, order_id, payment_id, signature):
        expected = hmac.new(
            self.api_secret.encode(),
            f"{order_id}|{payment_id}".encode(),
            hashlib.sha256,
        ).hexdigest()
        if hmac.compare_digest(expected, signature):
            return {"success": True, "verified": True}
        logger.warning("Razorpay signature mismatch for order %s, payment %s", order_id, payment_id)
        return {"success": False, "verified": False}

    def verify_payment_by_id(self, payment_id):
        try:
            payment = self.client.payment.fetch(payment_id)
            if payment.get("status") == "captured":
                return {"success": True, "status": "captured", "payment": payment}
            return {"success": False, "status": payment.get("status"), "payment": payment}
        except Exception as e:
            logger.error("Razorpay payment fetch failed: %s", e)
            raise PaymentGatewayError(str(e))

    def process_refund(self, transaction_id, amount=None):
        try:
            if amount:
                amount_paise = int(Decimal(str(amount)) * 100)
                refund = self.client.payment.refund(transaction_id, {"amount": amount_paise})
            else:
                refund = self.client.payment.refund(transaction_id)
            logger.info("Razorpay refund processed: %s", refund.get("id"))
            return {"success": True, "refund_id": refund["id"], "status": refund["status"]}
        except Exception as e:
            logger.error("Razorpay refund failed: %s", e)
            raise RefundFailedError(str(e))

    def capture_payment(self, payment_id, amount):
        try:
            amount_paise = int(Decimal(str(amount)) * 100)
            result = self.client.payment.capture(payment_id, amount_paise)
            return {"success": True, "status": result.get("status")}
        except Exception as e:
            logger.error("Razorpay capture failed: %s", e)
            raise PaymentGatewayError(str(e))

    @classmethod
    def verify_webhook(cls, payload, signature, webhook_secret):
        expected = hmac.new(
            webhook_secret.encode(),
            payload.encode() if isinstance(payload, str) else payload,
            hashlib.sha256,
        ).hexdigest()
        return hmac.compare_digest(expected, signature)
