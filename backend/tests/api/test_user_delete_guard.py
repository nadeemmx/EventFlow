"""Regression tests for QA-TEST-REPORT-ROLES.md F-4 (P2).

``UserViewSet`` was a plain ``ModelViewSet``, so ``DELETE /users/<id>/`` was an
unguarded hard delete: no confirmation, no OWNER guard, and no ``audit_logs``
row. An automated RBAC sweep issued ``DELETE /users/1/`` and destroyed the
Owner fixture — recorded as a harness incident in the QA report.

The fix routes the viewset's destroy through ``UserService.delete_user``
(guard + audit) and requires the caller to restate the target's email.
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.audit_logs.models import AuditLog
from apps.tenants.models import Tenant
from apps.users.models import User
from core.choices import UserRole


class UserDeleteGuardTests(TestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Alpha Events", owner_name="Owner",
            email="alpha@test.com", mobile="9999999999", status="ACTIVE")
        self.owner = User.objects.create_user(
            email="owner@test.com", password="ownerpass123",
            full_name="Tenant Owner", tenant=self.tenant, role=UserRole.OWNER)
        self.staff = User.objects.create_user(
            email="staff@test.com", password="staffpass123",
            full_name="Staff Member", tenant=self.tenant, role=UserRole.STAFF)
        self.client = APIClient()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer "
                               f"{RefreshToken.for_user(self.owner).access_token}")

    def _delete(self, pk, confirm=None, client=None):
        client = client or self.client
        url = f"/api/v1/users/{pk}/"
        if confirm is not None:
            url = f"{url}?confirm={confirm}"
        return client.delete(url)

    def test_delete_without_confirmation_is_rejected_and_user_survives(self):
        resp = self._delete(self.staff.pk)
        self.assertEqual(resp.status_code, 400, resp.data)
        self.assertTrue(User.objects.filter(pk=self.staff.pk).exists(),
                        "user was deleted without confirmation")

    def test_wrong_confirmation_is_rejected_and_user_survives(self):
        resp = self._delete(self.staff.pk, confirm="someone-else@test.com")
        self.assertEqual(resp.status_code, 400, resp.data)
        self.assertTrue(User.objects.filter(pk=self.staff.pk).exists())

    def test_correct_confirmation_deletes_and_writes_an_audit_row(self):
        resp = self._delete(self.staff.pk, confirm="staff@test.com")
        self.assertEqual(resp.status_code, 200, resp.data)
        self.assertFalse(User.objects.filter(pk=self.staff.pk).exists())

        log = AuditLog.objects.filter(
            module="USERS", action="DELETE", record_id=self.staff.pk
        ).first()
        self.assertIsNotNone(log, "no audit row written for the deletion")
        self.assertEqual(log.tenant_id, self.tenant.id)
        self.assertEqual(log.user_id, self.owner.id)
        self.assertIn("staff@test.com", log.old_data)
        self.assertIn("STAFF", log.old_data)

    def test_confirmation_is_case_insensitive(self):
        resp = self._delete(self.staff.pk, confirm="Staff@Test.com")
        self.assertEqual(resp.status_code, 200, resp.data)
        self.assertFalse(User.objects.filter(pk=self.staff.pk).exists())

    def test_owner_cannot_be_deleted(self):
        resp = self._delete(self.owner.pk, confirm="owner@test.com")
        self.assertEqual(resp.status_code, 400, resp.data)
        self.assertTrue(User.objects.filter(pk=self.owner.pk).exists())

    def test_staff_role_is_blocked_by_permissions_before_the_guard(self):
        """MANAGER has no ``users.destroy`` grant, so the permission layer
        answers first. Pinned so a future matrix change that suddenly grants
        it is a conscious decision."""
        actor = User.objects.create_user(
            email="actor@test.com", password="actorpass123",
            full_name="Actor", tenant=self.tenant, role=UserRole.MANAGER)
        client = APIClient()
        client.credentials(
            HTTP_AUTHORIZATION=f"Bearer "
                               f"{RefreshToken.for_user(actor).access_token}")
        resp = self._delete(self.staff.pk, confirm="staff@test.com",
                            client=client)
        self.assertEqual(resp.status_code, 403, resp.data)
        self.assertTrue(User.objects.filter(pk=self.staff.pk).exists())

    def test_super_admin_cannot_delete_their_own_account(self):
        """SUPER_ADMIN short-circuits the permission matrix, so it reaches the
        self-delete guard — unlike MANAGER above."""
        admin = User.objects.create_user(
            email="admin@test.com", password="adminpass123",
            full_name="Super Admin", tenant=None, role=UserRole.SUPER_ADMIN)
        client = APIClient()
        client.credentials(
            HTTP_AUTHORIZATION=f"Bearer "
                               f"{RefreshToken.for_user(admin).access_token}")
        resp = self._delete(admin.pk, confirm="admin@test.com", client=client)
        self.assertEqual(resp.status_code, 400, resp.data)
        self.assertTrue(User.objects.filter(pk=admin.pk).exists())
