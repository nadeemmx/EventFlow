import logging
from smtplib import SMTPException
from django.core.mail import send_mail
from django.conf import settings
from gateway.messaging.base import MessagingProvider, MessagingResult

logger = logging.getLogger(__name__)


class EmailProvider(MessagingProvider):
    MAX_RETRIES = 3

    def send_email(self, to, subject, body, html=False, from_email=None):
        last_error = None
        for attempt in range(self.MAX_RETRIES):
            try:
                sent = send_mail(
                    subject=subject,
                    message=body,
                    from_email=from_email or settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[to],
                    html_message=body if html else None,
                    fail_silently=False,
                )
                if sent:
                    logger.info("Email sent to %s: %s", to, subject)
                    return MessagingResult(success=True, message="Email sent")
                last_error = Exception("send_mail returned 0")
            except SMTPException as e:
                last_error = e
                logger.warning("Email attempt %d/%d failed to %s: %s", attempt + 1, self.MAX_RETRIES, to, e)
            except Exception as e:
                last_error = e
                logger.error("Email error to %s: %s", to, e)
                break
        logger.error("Email failed to %s after %d attempts: %s", to, self.MAX_RETRIES, last_error)
        return MessagingResult(success=False, message=str(last_error))

    def send_whatsapp(self, to, message):
        raise NotImplementedError("WhatsApp not supported via EmailProvider")
