from repositories.subscription_repository import (
    SubscriptionPlanRepository, SubscriptionRepository, CreditBalanceRepository
)
from repositories.audit_repository import AuditRepository
from services.base import BaseService
from core.choices import SubscriptionStatus, BillingCycle
from core.exceptions import ValidationException
from django.utils import timezone
from datetime import timedelta


class SubscriptionService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.plan_repo = SubscriptionPlanRepository()
        self.repo = SubscriptionRepository()
        self.credit_repo = CreditBalanceRepository()
        self.audit_repo = AuditRepository(None, self.user)

    def get_repository(self):
        return self.repo

    def get_current(self, tenant):
        return self.repo.get_active(tenant)

    def renew(self, tenant, plan_id, billing_cycle):
        plan = self.plan_repo.get_by_id(plan_id)
        old_sub = self.repo.get_active(tenant)
        if old_sub:
            old_sub.status = SubscriptionStatus.EXPIRED
            old_sub.save()
        days = {
            BillingCycle.MONTHLY: 30,
            BillingCycle.QUARTERLY: 90,
            BillingCycle.YEARLY: 365,
        }
        duration = days.get(billing_cycle, 30)
        sub = self.repo.create(
            tenant=tenant,
            plan=plan,
            start_date=timezone.now().date(),
            end_date=timezone.now().date() + timedelta(days=duration),
            billing_cycle=billing_cycle,
            status=SubscriptionStatus.ACTIVE,
        )
        tenant.subscription_plan = plan
        tenant.subscription_status = SubscriptionStatus.ACTIVE
        tenant.save()
        self.audit_repo.log(
            tenant=tenant, user=self.user,
            module="SUBSCRIPTION", action="RENEW",
            record_id=sub.id,
        )
        return sub
