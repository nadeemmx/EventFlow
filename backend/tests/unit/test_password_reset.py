import pytest
from django.contrib.auth import get_user_model
from apps.authentication.models import PasswordResetCode
from tests.factories import UserFactory

User = get_user_model()


@pytest.mark.django_db
class TestPasswordResetCode:
    def test_create_for_user_returns_raw_code(self):
        user = UserFactory()
        reset_code, raw_code = PasswordResetCode.create_for_user(user)
        assert raw_code is not None
        assert len(raw_code) > 20
        assert reset_code.user == user
        assert reset_code.code != raw_code

    def test_verify_code_valid(self):
        user = UserFactory()
        reset_code, raw_code = PasswordResetCode.create_for_user(user)
        assert reset_code.verify_code(raw_code) is True

    def test_verify_code_invalid(self):
        user = UserFactory()
        reset_code, _ = PasswordResetCode.create_for_user(user)
        assert reset_code.verify_code("wrong-code") is False

    def test_multiple_codes_for_user(self):
        user = UserFactory()
        code1, raw1 = PasswordResetCode.create_for_user(user)
        code2, raw2 = PasswordResetCode.create_for_user(user)
        assert code1.pk != code2.pk
        assert raw1 != raw2
        assert PasswordResetCode.objects.filter(user=user).count() == 2
