import pytest
from django.test import override_settings


@pytest.fixture(autouse=True)
def enable_db_access(db):
    pass
