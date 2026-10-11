from django.contrib.auth.models import AnonymousUser
from django.http import HttpResponse
from django.test import RequestFactory, TestCase

from apps.tenants.models import Tenant
from apps.users.models import User
from core.logging_middleware import RequestLoggingMiddleware
from gateway.messaging.email_provider import mask_email
from gateway.messaging.whatsapp_provider import mask_mobile
from core.choices import UserRole


class MaskingTests(TestCase):
    def test_mask_email_hides_identity(self):
        masked = mask_email("mark@example.com")
        self.assertEqual(masked, "ma***@ex***.com")
        self.assertNotIn("mark@example.com", masked)
        self.assertTrue(masked.endswith(".com"))

    def test_mask_email_without_domain(self):
        self.assertEqual(mask_email("not-an-email"), "***")

    def test_mask_email_handles_empty_value(self):
        self.assertEqual(mask_email(None), "***")

    def test_mask_mobile_hides_middle_digits(self):
        masked = mask_mobile("+91999999998")
        self.assertTrue(masked.startswith("+91"))
        self.assertTrue(masked.endswith("998"))
        self.assertIn("*", masked)
        self.assertNotIn("999999999", masked)

    def test_mask_mobile_short_value(self):
        self.assertEqual(mask_mobile("12345"), "*****")


class RequestLoggingPrivacyTests(TestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Alpha Venue", owner_name="Owner",
            email="alpha@test.com", mobile="1111111111",
        )
        self.user = User.objects.create_user(
            email="admin@test.com", password="StrongPass123!",
            full_name="Jane Doe", tenant=self.tenant, role=UserRole.OWNER,
        )
        self.factory = RequestFactory()

    def test_logs_user_id_instead_of_pii(self):
        request = self.factory.get("/api/v1/tenants/")
        request.user = self.user
        middleware = RequestLoggingMiddleware(lambda req: HttpResponse("ok"))
        with self.assertLogs("api", level="INFO") as captured:
            middleware(request)
        record = captured.records[-1]
        self.assertEqual(record.user, str(self.user.id))
        logged = str(record.__dict__)
        self.assertNotIn(self.user.email, logged)
        self.assertNotIn(self.user.full_name, logged)

    def test_logs_anonymous_for_unauthenticated(self):
        request = self.factory.get("/api/v1/tenants/")
        request.user = AnonymousUser()
        middleware = RequestLoggingMiddleware(lambda req: HttpResponse("ok"))
        with self.assertLogs("api", level="INFO") as captured:
            middleware(request)
        record = captured.records[-1]
        self.assertEqual(record.user, "anonymous")
