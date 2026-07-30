from rest_framework import serializers
from apps.audit_logs.models import AuditLog


class AuditLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = AuditLog
        fields = [
            "id", "user", "module", "action",
            "record_id", "old_data", "new_data",
            "ip_address", "created_at",
        ]
        read_only_fields = ["id", "created_at"]
