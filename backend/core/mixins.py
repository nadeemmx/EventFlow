class TimeStampedMixin:
    created_at = None
    updated_at = None

class SoftDeleteMixin:
    is_deleted = False
    deleted_at = None
    deleted_by = None

class AuditMixin:
    created_by = None
    updated_by = None
