from django.core import mail
from rest_framework.test import APITestCase

from apps.privacy.models import ContactMessage, PrivacyRequest
from apps.tenants.models import Tenant
from apps.users.models import User
from core.choices import UserRole
from tests.factories import TenantFactory, UserFactory


class ContactEndpointTests(APITestCase):
    url = "/api/v1/contact/"

    def test_requires_privacy_acknowledgement(self):
        response = self.client.post(
            self.url,
            {"name": "A", "email": "a@example.com", "message": "Hello"},
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("privacy_acknowledged", response.data["errors"])
        self.assertEqual(ContactMessage.objects.count(), 0)

    def test_creates_contact_message(self):
        response = self.client.post(
            self.url,
            {
                "source": "contact",
                "name": "Test Person",
                "email": "Person@Example.com",
                "subject": "Sales",
                "message": "Do you support multi-venue?",
                "privacy_acknowledged": True,
                "marketing_opt_in": True,
            },
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertTrue(response.data["success"])
        self.assertTrue(response.data["data"]["reference"].startswith("CM-"))
        message = ContactMessage.objects.get()
        self.assertEqual(message.email, "person@example.com")
        self.assertEqual(message.source, "contact")
        self.assertTrue(message.marketing_opt_in)
        self.assertGreaterEqual(len(mail.outbox), 1)

    def test_rejects_invalid_email(self):
        response = self.client.post(
            self.url,
            {
                "name": "A",
                "email": "not-an-email",
                "message": "Hello",
                "privacy_acknowledged": True,
            },
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(ContactMessage.objects.count(), 0)

    def test_rejects_unknown_source(self):
        response = self.client.post(
            self.url,
            {
                "source": "newsletter",
                "name": "A",
                "email": "a@example.com",
                "message": "Hello",
                "privacy_acknowledged": True,
            },
            format="json",
        )
        self.assertEqual(response.status_code, 400)

    def test_rejects_non_pdf_resume(self):
        response = self.client.post(
            self.url,
            {
                "source": "careers",
                "name": "A",
                "email": "a@example.com",
                "message": "Application",
                "privacy_acknowledged": True,
                "resume": ("resume.exe", b"MZ", "application/octet-stream"),
            },
            format="multipart",
        )
        self.assertEqual(response.status_code, 400)


class PrivacyRequestEndpointTests(APITestCase):
    submit_url = "/api/v1/privacy/submit/"
    list_url = "/api/v1/privacy/requests/"

    def test_anonymous_submission(self):
        response = self.client.post(
            self.submit_url,
            {
                "email": "subject@example.com",
                "request_type": "ERASURE",
                "description": "Please delete my data",
                "privacy_acknowledged": True,
            },
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertTrue(response.data["data"]["reference"].startswith("PR-"))
        request_obj = PrivacyRequest.objects.get()
        self.assertEqual(request_obj.status, PrivacyRequest.Status.SUBMITTED)
        self.assertIsNone(request_obj.tenant)
        self.assertGreaterEqual(len(mail.outbox), 1)

    def test_rejects_unknown_request_type(self):
        response = self.client.post(
            self.submit_url,
            {"email": "a@example.com", "request_type": "DELETE_EVERYTHING"},
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(PrivacyRequest.objects.count(), 0)

    def test_list_requires_authentication(self):
        response = self.client.get(self.list_url)
        self.assertIn(response.status_code, (401, 403))

    def test_owner_sees_only_own_tenant_requests(self):
        own_tenant = TenantFactory()
        other_tenant = TenantFactory()
        owner = UserFactory(tenant=own_tenant, role=UserRole.OWNER)

        PrivacyRequest.objects.create(
            email="a@example.com",
            request_type="ACCESS",
            description="mine",
            tenant=own_tenant,
        )
        PrivacyRequest.objects.create(
            email="b@example.com",
            request_type="ACCESS",
            description="theirs",
            tenant=other_tenant,
        )
        PrivacyRequest.objects.create(
            email="anon@example.com",
            request_type="ACCESS",
            description="anonymous",
            tenant=None,
        )

        self.client.force_authenticate(user=owner)
        response = self.client.get(self.list_url)
        self.assertEqual(response.status_code, 200)
        results = response.data["results"]
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]["description"], "mine")

    def test_super_admin_sees_all_requests(self):
        TenantFactory()
        PrivacyRequest.objects.create(
            email="a@example.com", request_type="ACCESS", tenant=None
        )
        PrivacyRequest.objects.create(
            email="b@example.com", request_type="ERASURE", tenant=TenantFactory()
        )
        super_admin = User.objects.create_user(
            email="super@example.com",
            password="testpass123",
            full_name="Super Admin",
            role=UserRole.SUPER_ADMIN,
            tenant=None,
        )
        self.client.force_authenticate(user=super_admin)
        response = self.client.get(self.list_url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["count"], 2)

    def test_owner_cannot_update_request_without_permission_module(self):
        tenant = TenantFactory()
        owner = UserFactory(tenant=tenant, role=UserRole.OWNER)
        request_obj = PrivacyRequest.objects.create(
            email="a@example.com", request_type="ACCESS", tenant=tenant
        )
        self.client.force_authenticate(user=owner)
        response = self.client.patch(
            f"{self.list_url}{request_obj.pk}/",
            {"status": PrivacyRequest.Status.ACTIONED},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        request_obj.refresh_from_db()
        self.assertEqual(request_obj.status, PrivacyRequest.Status.ACTIONED)
        self.assertIsNotNone(request_obj.responded_at)

    def test_owner_cannot_touch_other_tenant_request(self):
        tenant_a = TenantFactory()
        tenant_b = TenantFactory()
        owner_a = UserFactory(tenant=tenant_a, role=UserRole.OWNER)
        request_b = PrivacyRequest.objects.create(
            email="b@example.com", request_type="ACCESS", tenant=tenant_b
        )
        self.client.force_authenticate(user=owner_a)
        detail = self.client.get(f"{self.list_url}{request_b.pk}/")
        self.assertEqual(detail.status_code, 404)
        patch = self.client.patch(
            f"{self.list_url}{request_b.pk}/",
            {"status": PrivacyRequest.Status.CLOSED},
            format="json",
        )
        self.assertEqual(patch.status_code, 404)
        request_b.refresh_from_db()
        self.assertEqual(request_b.status, PrivacyRequest.Status.SUBMITTED)

    def test_manager_role_has_no_access(self):
        tenant = TenantFactory()
        manager = UserFactory(tenant=tenant, role=UserRole.MANAGER)
        self.client.force_authenticate(user=manager)
        response = self.client.get(self.list_url)
        self.assertEqual(response.status_code, 403)
