import pytest
from django.db import IntegrityError
from django.utils import timezone
from apps.subscriptions.models import SubscriptionPlan, Subscription, CreditBalance, CreditTransaction
from tests.factories import SubscriptionPlanFactory, SubscriptionFactory, TenantFactory
from core.choices import SubscriptionPlanName, BillingCycle, SubscriptionStatus


@pytest.mark.django_db
class TestSubscriptionPlanModel:
    def test_create_plan(self):
        plan = SubscriptionPlan.objects.create(
            plan_name=SubscriptionPlanName.PROFESSIONAL,
            monthly_price=1999,
            max_users=15,
            max_venues=5,
        )
        assert plan.plan_name == SubscriptionPlanName.PROFESSIONAL
        assert plan.monthly_price == 1999
        assert plan.max_users == 15
        assert plan.max_venues == 5
        assert plan.status == "ACTIVE"

    def test_string_representation(self):
        plan = SubscriptionPlanFactory(plan_name=SubscriptionPlanName.ENTERPRISE)
        assert str(plan) == "Enterprise"

    def test_default_values(self):
        plan = SubscriptionPlan.objects.create(
            plan_name=SubscriptionPlanName.STARTER,
        )
        assert plan.monthly_price == 0
        assert plan.yearly_price == 0
        assert plan.max_users == 3
        assert plan.max_venues == 1
        assert plan.max_bookings_per_month == 100
        assert plan.storage_limit_mb == 2048
        assert plan.features == {}

    def test_max_users_positive(self):
        plan = SubscriptionPlanFactory(max_users=0)
        assert plan.max_users == 0


@pytest.mark.django_db
class TestSubscriptionModel:
    def test_create_subscription(self):
        tenant = TenantFactory()
        plan = SubscriptionPlanFactory()
        sub = Subscription.objects.create(
            tenant=tenant,
            plan=plan,
            start_date=timezone.now().date(),
            end_date=timezone.now().date() + timezone.timedelta(days=30),
            billing_cycle=BillingCycle.MONTHLY,
            status=SubscriptionStatus.ACTIVE,
        )
        assert sub.tenant == tenant
        assert sub.plan == plan
        assert sub.billing_cycle == BillingCycle.MONTHLY
        assert sub.status == SubscriptionStatus.ACTIVE

    def test_string_representation(self):
        tenant = TenantFactory(business_name="Acme")
        sub = SubscriptionFactory(tenant=tenant, status=SubscriptionStatus.ACTIVE)
        assert str(sub) == "Acme - Active"

    def test_default_status_factory(self):
        sub = SubscriptionFactory()
        assert sub.status == SubscriptionStatus.ACTIVE

    def test_default_billing_cycle_factory(self):
        sub = SubscriptionFactory()
        assert sub.billing_cycle == BillingCycle.MONTHLY

    def test_tenant_relationship(self):
        tenant = TenantFactory()
        sub = SubscriptionFactory(tenant=tenant)
        assert sub.tenant == tenant
        assert list(tenant.subscriptions.all()) == [sub]

    def test_plan_nullable(self):
        sub = SubscriptionFactory(plan=None)
        assert sub.plan is None


@pytest.mark.django_db
class TestCreditBalanceModel:
    def test_create_credit_balance(self):
        tenant = TenantFactory()
        credit = CreditBalance.objects.create(
            tenant=tenant,
            credit_type="SMS",
            balance=100,
        )
        assert credit.tenant == tenant
        assert credit.credit_type == "SMS"
        assert credit.balance == 100

    def test_default_balance(self):
        tenant = TenantFactory()
        credit = CreditBalance.objects.create(
            tenant=tenant,
            credit_type="EMAIL",
        )
        assert credit.balance == 0

    def test_unique_together_constraint(self):
        tenant = TenantFactory()
        CreditBalance.objects.create(tenant=tenant, credit_type="SMS")
        with pytest.raises(IntegrityError):
            CreditBalance.objects.create(tenant=tenant, credit_type="SMS")

    def test_different_tenants_same_type_allowed(self):
        t1 = TenantFactory()
        t2 = TenantFactory()
        CreditBalance.objects.create(tenant=t1, credit_type="SMS")
        CreditBalance.objects.create(tenant=t2, credit_type="SMS")

    def test_tenant_relationship(self):
        tenant = TenantFactory()
        c1 = CreditBalance.objects.create(tenant=tenant, credit_type="SMS")
        c2 = CreditBalance.objects.create(tenant=tenant, credit_type="EMAIL")
        assert list(tenant.credit_balances.all()) == [c2, c1]


@pytest.mark.django_db
class TestCreditTransactionModel:
    def test_create_transaction(self):
        tenant = TenantFactory()
        credit = CreditBalance.objects.create(tenant=tenant, credit_type="SMS")
        txn = CreditTransaction.objects.create(
            tenant=tenant,
            credit_balance=credit,
            quantity=50,
            transaction_type="PURCHASE",
            description="Purchased 50 SMS credits",
        )
        assert txn.tenant == tenant
        assert txn.credit_balance == credit
        assert txn.quantity == 50
        assert txn.transaction_type == "PURCHASE"
        assert txn.description == "Purchased 50 SMS credits"
