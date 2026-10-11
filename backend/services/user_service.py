from repositories.user_repository import UserRepository
from repositories.audit_repository import AuditRepository
from services.base import BaseService
from core.choices import UserRole
from core.exceptions import ValidationException, ConflictException


class UserService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = UserRepository(self.tenant, self.user)
        self.audit_repo = AuditRepository(self.tenant, self.user)

    def get_repository(self):
        return self.repo

    def create_user(self, data):
        password = data.get("password")
        if not password:
            raise ValidationException("Password is required")
        if self.tenant:
            existing = self.repo.get_by_email(data["email"])
            if existing and existing.tenant_id == self.tenant.id:
                raise ConflictException("Email already exists in this tenant")
        user = self.repo.create(
            tenant=self.tenant,
            full_name=data["full_name"],
            email=data["email"],
            mobile=data.get("mobile", ""),
            role=data.get("role", UserRole.STAFF),
        )
        user.set_password(password)
        user.save()
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="USERS", action="CREATE",
            record_id=user.id,
        )
        return user

    def update_user(self, user_id, data):
        data = dict(data)
        password = data.pop("password", None)
        user = self.repo.get_by_id(user_id)
        old_role = user.role
        user = self.repo.update(user, **data)
        if password:
            user.set_password(password)
            user.save()
        if "role" in data and data["role"] != old_role:
            self.audit_repo.log(
                tenant=self.tenant, user=self.user,
                module="USERS", action="ROLE_CHANGE",
                record_id=user.id,
                old_data=f"{{'role': '{old_role}'}}",
                new_data=f"{{'role': '{user.role}'}}",
            )
        return user

    def activate_user(self, user_id):
        user = self.repo.get_by_id(user_id)
        return self.repo.update(user, is_active=True)

    def deactivate_user(self, user_id):
        user = self.repo.get_by_id(user_id)
        if user.role == UserRole.OWNER:
            raise ValidationException("Cannot deactivate owner")
        return self.repo.update(user, is_active=False)

    def delete_user(self, user_id):
        """Hard-delete a user, with the guards the raw viewset delete lacked.

        ``UserViewSet`` was a plain ``ModelViewSet``, so DELETE ran
        ``instance.delete()`` directly — no OWNER guard, no confirmation, no
        audit row. QA-TEST-REPORT-ROLES.md F-4 records an automated RBAC sweep
        hard-deleting the Owner fixture that way.

        Hard delete is deliberate for users rather than the soft delete used
        for customers/staff: a user row carries a password hash, so leaving it
        behind after a "delete" is worse for GDPR than removing it. What was
        missing was the trail, which is written below.

        ``UserRepository.delete`` routes through ``BaseRepository.delete``,
        which hard-deletes precisely because ``User`` has no ``is_deleted``
        field.
        """
        user = self.repo.get_by_id(user_id)
        if user.role == UserRole.OWNER:
            raise ValidationException("Cannot delete owner")
        if self.user and user.id == self.user.id:
            raise ValidationException("Cannot delete your own account")
        # Capture the identity first and write the row *after* the delete:
        # ``AuditLog.user`` is SET_NULL, so the log survives, and ``record_id``
        # is a plain integer rather than an FK. Storing the identifying fields
        # in old_data keeps the trail meaningful once the row is gone.
        identity = (
            f"{{'email': '{user.email}', 'full_name': '{user.full_name}', "
            f"'role': '{user.role}'}}"
        )
        record_id = user.id
        self.repo.delete(user)
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="USERS", action="DELETE",
            record_id=record_id,
            old_data=identity,
        )
        return user
