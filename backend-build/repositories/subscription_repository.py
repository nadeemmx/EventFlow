from repositories.base import BaseRepository
from apps.subscriptions.models import SubscriptionPlan, Subscription, CreditBalance, CreditTransaction


class SubscriptionPlanRepository(BaseRepository):
    model = SubscriptionPlan


class SubscriptionRepository(BaseRepository):
    model = Subscription

    def get_queryset(self):
        return self.model.objects.all()

    def get_active(self, tenant):
        return self.model.objects.filter(
            tenant=tenant, status__in=["ACTIVE", "TRIAL"]
        ).first()


class CreditBalanceRepository(BaseRepository):
    model = CreditBalance


class CreditTransactionRepository(BaseRepository):
    model = CreditTransaction
