from rest_framework import serializers
from apps.tasks.models import Task


class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = [
            "id", "booking", "assigned_to", "title",
            "description", "priority", "status",
            "due_date", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class TaskStatusSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=["OPEN", "IN_PROGRESS", "COMPLETED", "CANCELLED"])
