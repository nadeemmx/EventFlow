from repositories.task_repository import TaskRepository
from repositories.audit_repository import AuditRepository
from services.base import BaseService
from core.choices import TaskStatus
from core.exceptions import ValidationException


class TaskService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = TaskRepository(self.tenant, self.user)
        self.audit_repo = AuditRepository(self.tenant, self.user)

    def get_repository(self):
        return self.repo

    def change_status(self, task_id, new_status):
        task = self.repo.get_by_id(task_id)
        if task.status == TaskStatus.COMPLETED:
            raise ValidationException("Completed task cannot be edited")
        old_status = task.status
        task.status = new_status
        task.save()
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="TASKS", action="STATUS_CHANGE",
            record_id=task.id,
            old_data=f"{{'status': '{old_status}'}}",
            new_data=f"{{'status': '{new_status}'}}",
        )
        return task
