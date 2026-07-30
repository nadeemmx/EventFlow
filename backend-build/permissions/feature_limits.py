from rest_framework.permissions import BasePermission
from core.exceptions import SubscriptionLimitException


class FeatureLimitMixin:
    def check_tenant_limit(self, tenant, limit_field, current_count_field=None):
        plan = tenant.subscription_plan
        if not plan:
            return
        limit = getattr(plan, limit_field, None)
        if limit is None:
            return
        if current_count_field:
            from apps.subscriptions.models import Subscription
            # Delegate to service layer in actual implementation
            pass


class EnforceUserLimit(BasePermission):
    def has_permission(self, request, view):
        return True


class EnforceVenueLimit(BasePermission):
    def has_permission(self, request, view):
        return True
