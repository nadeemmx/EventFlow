from abc import ABC, abstractmethod


class MessagingProvider(ABC):
    @abstractmethod
    def send_email(self, to, subject, body, html=False):
        pass

    @abstractmethod
    def send_whatsapp(self, to, message):
        pass


class MessagingResult:
    def __init__(self, success, message, provider_ref=None):
        self.success = success
        self.message = message
        self.provider_ref = provider_ref
