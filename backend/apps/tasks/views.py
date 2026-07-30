from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from permissions.module_access import ModuleAccessPermission
from permissions.base import TenantScopedPermission
from apps.tasks.serializers import TaskSerializer, TaskStatusSerializer
from apps.tasks.models import Task
from services.task_service import TaskService
from core.responses import ok, error
from core.exceptions import ValidationException


class TaskViewSet(viewsets.ModelViewSet):
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated, ModuleAccessPermission, TenantScopedPermission]
    module_name = "tasks"
    search_fields = ["title"]
    filterset_fields = ["status", "priority", "assigned_to"]

    def get_queryset(self):
        tenant = self.request.tenant
        return Task.objects.filter(tenant=tenant, is_deleted=False).select_related("booking", "assigned_to")

    def perform_create(self, serializer):
        serializer.save(tenant=self.request.tenant, created_by=self.request.user)

    def perform_update(self, serializer):
        old_status = serializer.instance.status
        task = serializer.save()
        if old_status != task.status:
            from apps.audit_logs.models import AuditLog
            AuditLog.objects.create(
                tenant=task.tenant,
                user=self.request.user,
                module="TASKS",
                action="STATUS_CHANGE",
                record_id=task.id,
            )

    @action(detail=True, methods=["post"])
    def status(self, request, pk=None):
        serializer = TaskStatusSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            service = TaskService(request.tenant, request.user)
            task = service.change_status(pk, serializer.validated_data["status"])
            return ok(TaskSerializer(task).data, "Status updated")
        except ValidationException as e:
            return error(e.message)
