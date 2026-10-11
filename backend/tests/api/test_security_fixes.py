from rest_framework.test import APITestCase
from django.utils import timezone

from apps.tenants.models import Tenant
from apps.users.models import User
from apps.customers.models import Customer
from apps.venues.models import Venue
from apps.bookings.models import Booking
from apps.inventory.models import InventoryItem
from apps.notifications.models import Notification
from core.choices import UserRole


class TenantCreateSecurityTests(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Alpha Venue", owner_name="Owner",
            email="alpha@test.com", mobile="1111111111",
        )
        self.owner = User.objects.create_user(
            email="owner@test.com", password="StrongPass123!",
            full_name="Owner", tenant=self.tenant, role=UserRole.OWNER,
        )
        self.payload = {
            "business_name": "Sneaky Corp",
            "owner_name": "Sneaky",
            "email": "sneaky@corp.com",
            "mobile": "9999999999",
            "subscription_status": "ACTIVE",
            "status": "ACTIVE",
        }

    def test_anonymous_create_rejected(self):
        response = self.client.post("/api/v1/tenants/", self.payload)
        self.assertIn(response.status_code, (401, 403))
        self.assertFalse(Tenant.objects.filter(email="sneaky@corp.com").exists())

    def test_non_superadmin_create_forbidden(self):
        self.client.force_authenticate(user=self.owner)
        response = self.client.post("/api/v1/tenants/", self.payload)
        self.assertEqual(response.status_code, 403)
        self.assertFalse(Tenant.objects.filter(email="sneaky@corp.com").exists())


class TenantRegistrationPathTests(APITestCase):
    def test_register_creates_tenant_and_tokens(self):
        response = self.client.post("/api/v1/auth/register/", {
            "full_name": "New Owner",
            "email": "newowner@corp.com",
            "password": "StrongPass123!",
            "confirm_password": "StrongPass123!",
            "business_name": "New Biz",
            "mobile": "9999999999",
        })
        self.assertEqual(response.status_code, 201)
        self.assertTrue(response.data["success"])
        self.assertTrue(Tenant.objects.filter(email="newowner@corp.com").exists())
        self.assertIn("access_token", response.data["data"])
        self.assertIn("refresh_token", response.data["data"])


class TenantUpdateSecurityTests(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Alpha Venue", owner_name="Owner",
            email="alpha@test.com", mobile="1111111111",
        )
        self.owner = User.objects.create_user(
            email="owner@test.com", password="StrongPass123!",
            full_name="Owner", tenant=self.tenant, role=UserRole.OWNER,
        )
        self.client.force_authenticate(user=self.owner)

    def test_owner_cannot_change_subscription_or_status(self):
        response = self.client.patch(
            f"/api/v1/tenants/{self.tenant.id}/",
            {
                "business_name": "Renamed Venue",
                "subscription_status": "SUSPENDED",
                "status": "SUSPENDED",
                "subscription_plan": 9999,
            },
        )
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["success"])
        self.tenant.refresh_from_db()
        self.assertEqual(self.tenant.business_name, "Renamed Venue")
        self.assertEqual(self.tenant.subscription_status, "TRIAL")
        self.assertEqual(self.tenant.status, "ACTIVE")
        self.assertIsNone(self.tenant.subscription_plan_id)


class RefreshTokenSecurityTests(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Alpha Venue", owner_name="Owner",
            email="alpha@test.com", mobile="1111111111",
        )
        self.user = User.objects.create_user(
            email="owner@test.com", password="StrongPass123!",
            full_name="Owner", tenant=self.tenant, role=UserRole.OWNER,
        )

    def _login(self):
        response = self.client.post("/api/v1/auth/login/", {
            "email": "owner@test.com",
            "password": "StrongPass123!",
        })
        self.assertEqual(response.status_code, 200)
        return response.data["data"]

    def test_refresh_token_cannot_be_reused(self):
        tokens = self._login()
        refresh = tokens["refresh_token"]
        first = self.client.post("/api/v1/auth/refresh/", {"refresh_token": refresh})
        self.assertEqual(first.status_code, 200)
        second = self.client.post("/api/v1/auth/refresh/", {"refresh_token": refresh})
        self.assertEqual(second.status_code, 401)
        self.assertFalse(second.data["success"])
        rotated = first.data["data"]["refresh_token"]
        third = self.client.post("/api/v1/auth/refresh/", {"refresh_token": rotated})
        self.assertEqual(third.status_code, 200)

    def test_refresh_rejected_for_inactive_user(self):
        tokens = self._login()
        self.user.is_active = False
        self.user.save()
        response = self.client.post(
            "/api/v1/auth/refresh/", {"refresh_token": tokens["refresh_token"]}
        )
        self.assertEqual(response.status_code, 401)

    def test_refresh_rejected_for_suspended_tenant(self):
        tokens = self._login()
        self.tenant.status = "SUSPENDED"
        self.tenant.save()
        response = self.client.post(
            "/api/v1/auth/refresh/", {"refresh_token": tokens["refresh_token"]}
        )
        self.assertEqual(response.status_code, 401)

    def test_refresh_rejects_access_token(self):
        tokens = self._login()
        response = self.client.post(
            "/api/v1/auth/refresh/", {"refresh_token": tokens["access_token"]}
        )
        self.assertEqual(response.status_code, 401)


class BookingTenantIsolationTests(APITestCase):
    def setUp(self):
        self.tenant_a = Tenant.objects.create(
            business_name="Alpha Venue", owner_name="Owner",
            email="alpha@test.com", mobile="1111111111",
        )
        self.user_a = User.objects.create_user(
            email="owner@test.com", password="StrongPass123!",
            full_name="Owner", tenant=self.tenant_a, role=UserRole.OWNER,
        )
        self.tenant_b = Tenant.objects.create(
            business_name="Beta Venue", owner_name="Owner B",
            email="beta@test.com", mobile="2222222222",
        )
        self.customer_a = Customer.objects.create(
            tenant=self.tenant_a, full_name="Customer A", mobile="8888888881",
        )
        self.customer_b = Customer.objects.create(
            tenant=self.tenant_b, full_name="Customer B", mobile="8888888882",
        )
        self.venue_a = Venue.objects.create(
            tenant=self.tenant_a, name="Grand Hall A",
            venue_type="BANQUET_HALL", capacity=500,
            weekday_price=50000, weekend_price=75000,
        )
        self.venue_b = Venue.objects.create(
            tenant=self.tenant_b, name="Grand Hall B",
            venue_type="BANQUET_HALL", capacity=500,
            weekday_price=50000, weekend_price=75000,
        )
        self.client.force_authenticate(user=self.user_a)

    def _payload(self, **overrides):
        payload = {
            "venue": self.venue_a.id,
            "customer": self.customer_a.id,
            "event_type": "WEDDING",
            "event_date": str(timezone.now().date() + timezone.timedelta(days=30)),
            "guest_count": 100,
            "total_amount": 100000,
        }
        payload.update(overrides)
        return payload

    def test_rejects_other_tenants_customer(self):
        response = self.client.post(
            "/api/v1/bookings/", self._payload(customer=self.customer_b.id)
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("customer", response.data["errors"])
        self.assertEqual(Booking.objects.count(), 0)

    def test_rejects_other_tenants_venue(self):
        response = self.client.post(
            "/api/v1/bookings/", self._payload(venue=self.venue_b.id)
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("venue", response.data["errors"])
        self.assertEqual(Booking.objects.count(), 0)

    def test_accepts_own_tenant_records(self):
        response = self.client.post("/api/v1/bookings/", self._payload())
        self.assertEqual(response.status_code, 201)
        self.assertEqual(Booking.objects.count(), 1)

    def test_allocate_rejects_other_tenants_booking(self):
        item = InventoryItem.objects.create(
            tenant=self.tenant_a, item_name="Gold Chair",
            total_quantity=50, available_quantity=50,
        )
        booking_b = Booking.objects.create(
            tenant=self.tenant_b, booking_number="VF-2026-000099",
            venue=self.venue_b, customer=self.customer_b,
            event_type="WEDDING",
            event_date=timezone.now().date() + timezone.timedelta(days=10),
            guest_count=100, total_amount=100000, status="DRAFT",
        )
        response = self.client.post("/api/v1/inventory/allocate/", {
            "booking_id": booking_b.id,
            "inventory_item_id": item.id,
            "quantity": 5,
        })
        self.assertEqual(response.status_code, 400)
        self.assertFalse(response.data["success"])
        item.refresh_from_db()
        self.assertEqual(item.available_quantity, 50)


class NotificationPrivacyTests(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Alpha Venue", owner_name="Owner",
            email="alpha@test.com", mobile="1111111111",
        )
        self.user_a = User.objects.create_user(
            email="usera@test.com", password="StrongPass123!",
            full_name="User A", tenant=self.tenant, role=UserRole.STAFF,
        )
        self.user_b = User.objects.create_user(
            email="userb@test.com", password="StrongPass123!",
            full_name="User B", tenant=self.tenant, role=UserRole.STAFF,
        )
        self.mine = Notification.objects.create(
            tenant=self.tenant, user=self.user_a,
            title="Only for A", message="private",
        )
        self.theirs = Notification.objects.create(
            tenant=self.tenant, user=self.user_b,
            title="Only for B", message="private",
        )
        self.announcement = Notification.objects.create(
            tenant=self.tenant, user=None,
            title="Announcement", message="tenant wide",
        )
        self.client.force_authenticate(user=self.user_a)

    def test_list_shows_own_and_tenant_wide_only(self):
        response = self.client.get("/api/v1/notifications/")
        self.assertEqual(response.status_code, 200)
        titles = [row["title"] for row in response.data["results"]]
        self.assertIn("Only for A", titles)
        self.assertIn("Announcement", titles)
        self.assertNotIn("Only for B", titles)

    def test_mark_read_own_notification(self):
        response = self.client.post(
            f"/api/v1/notifications/{self.mine.id}/mark_read/"
        )
        self.assertEqual(response.status_code, 200)
        self.mine.refresh_from_db()
        self.assertEqual(self.mine.status, "READ")

    def test_mark_read_other_users_notification_rejected(self):
        response = self.client.post(
            f"/api/v1/notifications/{self.theirs.id}/mark_read/"
        )
        self.assertEqual(response.status_code, 404)
        self.theirs.refresh_from_db()
        self.assertNotEqual(self.theirs.status, "READ")

    def test_retrieve_other_users_notification_rejected(self):
        response = self.client.get(f"/api/v1/notifications/{self.theirs.id}/")
        self.assertEqual(response.status_code, 404)
