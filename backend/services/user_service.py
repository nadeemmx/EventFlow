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
        user.set_password(data["password"])
        user.save()
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="USERS", action="CREATE",
            record_id=user.id,
        )
        return user

    def update_user(self, user_id, data):
        user = self.repo.get_by_id(user_id)
        old_role = user.role
        user = self.repo.update(user, **data)
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
