from django.db import models
from django.core import signing
from django.conf import settings


class EncryptedTextField(models.TextField):
    def get_internal_type(self):
        return "TextField"

    def from_db_value(self, value, expression, connection):
        if value is None:
            return value
        try:
            return signing.loads(value)
        except (signing.BadSignature, Exception):
            return value

    def to_python(self, value):
        if value is None or not isinstance(value, str):
            return value
        try:
            return signing.loads(value)
        except (signing.BadSignature, Exception):
            return value

    def get_prep_value(self, value):
        if value is None:
            return None
        return signing.dumps(value, compress=True)

    def get_db_prep_save(self, value, connection):
        if value is None:
            return None
        return signing.dumps(value, compress=True)
