import factory
from django.utils import timezone
from apps.tenants.models import Tenant
from apps.users.models import User
from apps.customers.models import Customer
from apps.venues.models import Venue
from apps.bookings.models import Booking
from apps.subscriptions.models import SubscriptionPlan, Subscription
from core.choices import (
    UserRole, VenueType, VenueStatus, EventType,
    BookingStatus, SubscriptionPlanName, SubscriptionStatus, BillingCycle,
)


class TenantFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Tenant

    business_name = factory.Faker("company")
    owner_name = factory.Faker("name")
    email = factory.Faker("email")
    mobile = factory.Faker("phone_number")
    status = "ACTIVE"
    subscription_status = "ACTIVE"


class SubscriptionPlanFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = SubscriptionPlan

    plan_name = SubscriptionPlanName.PROFESSIONAL
    monthly_price = 1999
    max_users = 15
    max_venues = 5


class SubscriptionFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Subscription

    tenant = factory.SubFactory(TenantFactory)
    plan = factory.SubFactory(SubscriptionPlanFactory)
    start_date = timezone.now().date()
    end_date = timezone.now().date() + timezone.timedelta(days=30)
    billing_cycle = BillingCycle.MONTHLY
    status = SubscriptionStatus.ACTIVE


class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User

    tenant = factory.SubFactory(TenantFactory)
    full_name = factory.Faker("name")
    email = factory.Faker("email")
    mobile = factory.Faker("phone_number")
    role = UserRole.MANAGER
    is_active = True

    @factory.post_generation
    def password(obj, create, extracted, **kwargs):
        if extracted:
            obj.set_password(extracted)
        else:
            obj.set_password("Password123")
        if create:
            obj.save()


class CustomerFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Customer

    tenant = factory.SubFactory(TenantFactory)
    full_name = factory.Faker("name")
    mobile = factory.Faker("phone_number")
    email = factory.Faker("email")


class VenueFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Venue

    tenant = factory.SubFactory(TenantFactory)
    name = factory.Faker("company")
    venue_type = VenueType.BANQUET_HALL
    capacity = 200
    status = VenueStatus.ACTIVE
    weekday_price = 50000
    weekend_price = 75000


class BookingFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = Booking

    tenant = factory.SubFactory(TenantFactory)
    booking_number = factory.Sequence(lambda n: f"VF-2026-{n:06d}")
    venue = factory.SubFactory(VenueFactory)
    customer = factory.SubFactory(CustomerFactory)
    event_type = EventType.WEDDING
    event_date = timezone.now().date() + timezone.timedelta(days=30)
    guest_count = 100
    total_amount = 100000
    status = BookingStatus.DRAFT
