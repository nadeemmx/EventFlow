import logging
from gateway.messaging.base import MessagingProvider, MessagingResult

logger = logging.getLogger(__name__)


class WhatsAppProvider(MessagingProvider):
    MAX_RETRIES = 3

    def send_email(self, to, subject, body, html=False):
        raise NotImplementedError("Email not supported via WhatsAppProvider")

    def send_whatsapp(self, to, message):
        last_error = None
        for attempt in range(self.MAX_RETRIES):
            try:
                from django.conf import settings
                from apps.settings.models import WhatsAppSettings
                settings_obj = WhatsAppSettings.objects.filter(is_active=True).first()
                if not settings_obj or not settings_obj.api_key:
                    logger.warning("WhatsApp not configured, skipping message to %s", to)
                    return MessagingResult(success=False, message="WhatsApp not configured")

                provider_type = settings_obj.provider if settings_obj else "twilio"
                if provider_type == "twilio":
                    result = self._send_via_twilio(to, message, settings_obj)
                elif provider_type == "gupshup":
                    result = self._send_via_gupshup(to, message, settings_obj)
                else:
                    result = self._send_via_whatsapp_business(to, message, settings_obj)

                if result.success:
                    logger.info("WhatsApp sent to %s via %s", to, provider_type)
                    return result
                last_error = Exception(result.message)
            except Exception as e:
                last_error = e
                logger.warning("WhatsApp attempt %d/%d failed to %s: %s", attempt + 1, self.MAX_RETRIES, to, e)
        logger.error("WhatsApp failed to %s after %d attempts: %s", to, self.MAX_RETRIES, last_error)
        return MessagingResult(success=False, message=str(last_error))

    def _send_via_twilio(self, to, message, settings_obj):
        try:
            from twilio.rest import Client
            client = Client(settings_obj.api_key, settings_obj.business_account_id or settings_obj.api_key)
            client.messages.create(
                body=message,
                from_=f"whatsapp:{settings_obj.phone_number_id}",
                to=f"whatsapp:{to}",
            )
            return MessagingResult(success=True, message="WhatsApp sent via Twilio")
        except Exception as e:
            return MessagingResult(success=False, message=str(e))

    def _send_via_gupshup(self, to, message, settings_obj):
        import requests
        try:
            response = requests.post(
                "https://api.gupshup.io/sm/api/v1/msg",
                headers={"Content-Type": "application/x-www-form-urlencoded", "apikey": settings_obj.api_key},
                data={
                    "channel": "whatsapp",
                    "source": settings_obj.phone_number_id,
                    "destination": to,
                    "message": message,
                },
                timeout=10,
            )
            if response.status_code == 200:
                return MessagingResult(success=True, message="WhatsApp sent via Gupshup")
            return MessagingResult(success=False, message=f"Gupshup error: {response.status_code}")
        except Exception as e:
            return MessagingResult(success=False, message=str(e))

    def _send_via_whatsapp_business(self, to, message, settings_obj):
        import requests
        try:
            url = f"https://graph.facebook.com/v18.0/{settings_obj.phone_number_id}/messages"
            response = requests.post(
                url,
                headers={
                    "Authorization": f"Bearer {settings_obj.api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "messaging_product": "whatsapp",
                    "to": to,
                    "type": "text",
                    "text": {"body": message},
                },
                timeout=10,
            )
            if response.status_code == 200:
                return MessagingResult(success=True, message="WhatsApp sent via Business API")
            return MessagingResult(success=False, message=f"WABA error: {response.status_code}")
        except Exception as e:
            return MessagingResult(success=False, message=str(e))
