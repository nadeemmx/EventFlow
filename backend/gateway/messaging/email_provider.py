import logging
from smtplib import SMTPException
from django.core.mail import send_mail
from django.conf import settings
from gateway.messaging.base import MessagingProvider, MessagingResult

logger = logging.getLogger(__name__)


def mask_email(value):
    email = str(value or "")
    if "@" not in email:
        return "***"
    local, domain = email.rsplit("@", 1)
    if "." in domain:
        host, tld = domain.rsplit(".", 1)
        return f"{local[:2]}***@{host[:2]}***.{tld}"
    return f"{local[:2]}***@{domain[:2]}***"


class EmailProvider(MessagingProvider):
    MAX_RETRIES = 3

    def send_email(self, to, subject, body, html=False, from_email=None):
        last_error = None
        masked = mask_email(to)
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
                    logger.info("Email sent to %s: %s", masked, subject)
                    return MessagingResult(success=True, message="Email sent")
                last_error = Exception("send_mail returned 0")
            except SMTPException as e:
                last_error = e
                logger.warning("Email attempt %d/%d failed to %s: %s", attempt + 1, self.MAX_RETRIES, masked, e)
            except Exception as e:
                last_error = e
                logger.error("Email error to %s: %s", masked, e)
                break
        logger.error("Email failed to %s after %d attempts: %s", masked, self.MAX_RETRIES, last_error)
        return MessagingResult(success=False, message=str(last_error))

    def send_whatsapp(self, to, message, tenant=None):
        raise NotImplementedError("WhatsApp not supported via EmailProvider")
