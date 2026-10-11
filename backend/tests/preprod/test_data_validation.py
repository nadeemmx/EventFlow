"""Pre-production data validation and injection tests.

Covers checklist item #10 (Data Validation Testing) plus the injection
half of #18 (Penetration Testing): malformed, hostile and boundary input
must be rejected with a 4xx JSON envelope and must never surface a 500 or
corrupt data.
"""
import json

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APITestCase

from apps.customers.models import Customer
from apps.tenants.models import Tenant
from apps.users.models import User
from core.choices import UserRole


class DataValidationTestBase(APITestCase):
    def setUp(self):
        self.tenant = Tenant.objects.create(
            business_name="Validation Venue", owner_name="Owner",
            email="validation@test.com", mobile="9000000002",
        )
        self.owner = User.objects.create_user(
            email="validation-owner@test.com", password="ValidationPass123!",
            full_name="Owner", tenant=self.tenant, role=UserRole.OWNER,
        )
        self.client.force_authenticate(user=self.owner)

    def assertJsonError(self, response, expected_status):
        self.assertEqual(response.status_code, expected_status)
        self.assertTrue(response["Content-Type"].startswith("application/json"))
        body = json.loads(response.content)
        self.assertFalse(body["success"])
        return body


class RequiredFieldValidationTests(DataValidationTestBase):
    def test_missing_required_field_rejected(self):
        response = self.client.post("/api/v1/customers/", {"mobile": "9000000099"})
        self.assertJsonError(response, 400)
        self.assertEqual(Customer.objects.count(), 0)

    def test_null_required_field_rejected(self):
        response = self.client.post(
            "/api/v1/customers/", {"full_name": None, "mobile": "9000000098"},
            format="json",
        )
        self.assertJsonError(response, 400)

    def test_invalid_email_rejected(self):
        response = self.client.post(
            "/api/v1/customers/",
            {"full_name": "Bad Email", "mobile": "9000000097", "email": "not-an-email"},
        )
        self.assertJsonError(response, 400)
        self.assertEqual(Customer.objects.filter(email="not-an-email").count(), 0)

    def test_oversized_field_rejected(self):
        response = self.client.post(
            "/api/v1/customers/",
            {"full_name": "A" * 5000, "mobile": "9000000096"},
        )
        self.assertJsonError(response, 400)
        self.assertEqual(Customer.objects.filter(full_name__startswith="AAAA").count(), 0)

    def test_duplicate_mobile_in_tenant_rejected(self):
        """Was a KNOWN GAP: the (tenant, mobile) unique constraint existed in
        the database but the API did not pre-validate it, so a duplicate POST
        raised IntegrityError and surfaced as HTTP 500 instead of 400.
        Fixed by CustomerSerializer.validate_mobile (QA-TEST-REPORT.md P1-2).
        """
        Customer.objects.create(tenant=self.tenant, full_name="First", mobile="9000000095")
        response = self.client.post(
            "/api/v1/customers/", {"full_name": "Second", "mobile": "9000000095"},
            format="json",
        )
        self.assertJsonError(response, 400)
        self.assertEqual(Customer.objects.filter(mobile="9000000095").count(), 1)

    def test_invalid_booking_date_rejected(self):
        from apps.venues.models import Venue
        from apps.customers.models import Customer as C
        venue = Venue.objects.create(
            tenant=self.tenant, name="Val Hall", venue_type="BANQUET_HALL",
            capacity=100, weekday_price=1000, weekend_price=2000,
        )
        customer = C.objects.create(tenant=self.tenant, full_name="C", mobile="9000000094")
        response = self.client.post("/api/v1/bookings/", {
            "venue": venue.id,
            "customer": customer.id,
            "event_type": "WEDDING",
            "event_date": "31-13-2026",
            "guest_count": 10,
            "total_amount": 1000,
        })
        self.assertJsonError(response, 400)

    def test_wrong_types_rejected(self):
        response = self.client.post("/api/v1/customers/", {
            "full_name": {"nested": "object"}, "mobile": ["list"], "email": 12,
        }, format="json")
        self.assertJsonError(response, 400)

    def test_malformed_json_body_rejected(self):
        response = self.client.post(
            "/api/v1/customers/", data="{not json", content_type="application/json"
        )
        self.assertJsonError(response, 400)


class BoundaryAndRoundTripTests(DataValidationTestBase):
    def test_unicode_and_emoji_round_trip(self):
        name = "Ünïcødé Venue 😀 עברית"
        response = self.client.post(
            "/api/v1/customers/", {"full_name": name, "mobile": "9000000093"}
        )
        self.assertEqual(response.status_code, 201, response.content)
        customer = Customer.objects.get(mobile="9000000093")
        self.assertEqual(customer.full_name, name)

    def test_xss_payload_is_json_encoded_not_executed(self):
        payload = "<script>alert('xss')</script>"
        response = self.client.post(
            "/api/v1/customers/",
            {"full_name": payload, "mobile": "9000000092", "remarks": "<img src=x onerror=alert(1)>"},
        )
        self.assertEqual(response.status_code, 201, response.content)
        raw = response.content.decode()
        # the payload must survive as data, and the JSON body must not be
        # broken by unescaped quotes/control chars
        self.assertIn("script", raw)
        body = json.loads(raw)
        self.assertEqual(body["full_name"], payload)
        fetched = json.loads(self.client.get(f"/api/v1/customers/{body['id']}/").content)
        stored = fetched.get("data", fetched)
        self.assertEqual(stored["full_name"], payload)
        self.assertEqual(stored["remarks"], "<img src=x onerror=alert(1)>")

    def test_null_byte_in_field_does_not_500(self):
        response = self.client.post(
            "/api/v1/customers/", {"full_name": "Null\x00Byte", "mobile": "9000000091"}
        )
        self.assertNotEqual(response.status_code, 500, response.content)
        self.assertIn(response.status_code, (200, 201, 400), response.content)

    def test_unknown_extra_fields_are_ignored(self):
        response = self.client.post(
            "/api/v1/customers/",
            {"full_name": "Extra", "mobile": "9000000090", "is_admin": True,
             "__proto__": "x", "tenant": 999},
        )
        self.assertEqual(response.status_code, 201, response.content)
        customer = Customer.objects.get(mobile="9000000090")
        self.assertEqual(customer.tenant_id, self.tenant.id)
        self.assertFalse(hasattr(customer, "is_admin") and customer.is_admin)

    def test_zero_and_negative_amount_not_500(self):
        from apps.venues.models import Venue
        from apps.customers.models import Customer as C
        venue = Venue.objects.create(
            tenant=self.tenant, name="Neg Hall", venue_type="BANQUET_HALL",
            capacity=100, weekday_price=1000, weekend_price=2000,
        )
        customer = C.objects.create(tenant=self.tenant, full_name="N", mobile="9000000089")
        for amount in (0, -100):
            with self.subTest(amount=amount):
                response = self.client.post("/api/v1/bookings/", {
                    "venue": venue.id,
                    "customer": customer.id,
                    "event_type": "WEDDING",
                    "event_date": str(timezone.now().date() + timezone.timedelta(days=10)),
                    "guest_count": 10,
                    "total_amount": amount,
                })
                self.assertNotEqual(response.status_code, 500, response.content)


class InjectionTests(DataValidationTestBase):
    SQLI_PAYLOADS = [
        "' OR '1'='1",
        "1; DROP TABLE customers;--",
        "' UNION SELECT id, password FROM users--",
        "\" OR 1=1--",
        "%' AND SLEEP(5)--",
    ]

    def test_sqli_in_search_parameter(self):
        for payload in self.SQLI_PAYLOADS:
            with self.subTest(payload=payload):
                response = self.client.get(
                    "/api/v1/customers/", {"search": payload}
                )
                self.assertNotEqual(response.status_code, 500, response.content)
                self.assertIn(response.status_code, (200, 400), response.content)

    def test_sqli_in_ordering_parameter(self):
        for payload in ("id; DROP TABLE users--", "full_name, (SELECT password FROM users)",
                        "1 DESC; DELETE FROM customers"):
            with self.subTest(payload=payload):
                response = self.client.get(
                    "/api/v1/customers/", {"ordering": payload}
                )
                self.assertNotEqual(response.status_code, 500, response.content)

    def test_sqli_in_path_parameter(self):
        response = self.client.get("/api/v1/customers/1%27%20OR%20%271%27%3D%271/")
        self.assertNotEqual(response.status_code, 500, response.content)

    def test_database_survives_injection_attempts(self):
        Customer.objects.create(tenant=self.tenant, full_name="Survivor", mobile="9000000088")
        for payload in self.SQLI_PAYLOADS:
            self.client.get("/api/v1/customers/", {"search": payload})
            self.client.get("/api/v1/customers/", {"ordering": payload})
        self.assertEqual(Customer.objects.filter(mobile="9000000088").count(), 1)
        # all tables still queryable
        self.assertEqual(
            self.client.get("/api/v1/customers/").status_code, 200
        )

    def test_path_traversal_in_filter_param(self):
        response = self.client.get(
            "/api/v1/customers/", {"search": "../../../etc/passwd"}
        )
        self.assertNotEqual(response.status_code, 500, response.content)

    def test_hostile_filter_value_does_not_leak_other_tenants(self):
        other = Tenant.objects.create(
            business_name="Other Tenant", owner_name="Other",
            email="other-validation@test.com", mobile="9000000087",
        )
        Customer.objects.create(tenant=other, full_name="Secret", mobile="9000000086")
        response = self.client.get("/api/v1/customers/", {"search": "Secret"})
        self.assertEqual(response.status_code, 200)
        body = json.loads(response.content)
        self.assertEqual(body["count"], 0, "cross-tenant record leaked via search")
