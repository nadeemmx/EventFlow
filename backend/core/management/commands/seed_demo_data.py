from django.core.management.base import BaseCommand
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.subscriptions.models import SubscriptionPlan, Subscription
from core.choices import UserRole, SubscriptionPlanName, SubscriptionStatus, BillingCycle
from django.utils import timezone
from datetime import timedelta


class Command(BaseCommand):
    help = "Seed demo data for development"

    def handle(self, *args, **options):
        plan, _ = SubscriptionPlan.objects.get_or_create(
            plan_name=SubscriptionPlanName.PROFESSIONAL,
            defaults={
                "monthly_price": 1999,
                "yearly_price": 19990,
                "max_users": 15,
                "max_venues": 5,
                "max_bookings_per_month": 0,
                "storage_limit_mb": 10240,
                "status": "ACTIVE",
            },
        )
        tenant, _ = Tenant.objects.get_or_create(
            email="demo@eventflow.com",
            defaults={
                "business_name": "Demo Venue",
                "owner_name": "Demo Owner",
                "mobile": "+919999999999",
                "subscription_plan": plan,
                "subscription_status": "ACTIVE",
                "status": "ACTIVE",
            },
        )
        user, created = User.objects.get_or_create(
            email="owner@eventflow.com",
            defaults={
                "tenant": tenant,
                "full_name": "Owner User",
                "mobile": "+919999999998",
                "role": UserRole.OWNER,
                "is_active": True,
            },
        )
        if created:
            user.set_password("Password123")
            user.save()
        Subscription.objects.get_or_create(
            tenant=tenant,
            defaults={
                "plan": plan,
                "start_date": timezone.now().date(),
                "end_date": timezone.now().date() + timedelta(days=30),
                "billing_cycle": BillingCycle.MONTHLY,
                "status": SubscriptionStatus.ACTIVE,
            },
        )
        self.stdout.write(f"Demo data seeded. Login: owner@eventflow.com / Password123")
