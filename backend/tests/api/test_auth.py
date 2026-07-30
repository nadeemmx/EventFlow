import pytest
from django.test import TestCase


class TestAuthAPI(TestCase):
    def test_login_missing_fields(self):
        response = self.client.post("/api/v1/auth/login/", {}, content_type="application/json")
        self.assertEqual(response.status_code, 400)
