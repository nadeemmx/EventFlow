from django.db import models
from repositories.base import BaseRepository
from apps.customers.models import Customer


class CustomerRepository(BaseRepository):
    model = Customer

    def search(self, query):
        return self.get_queryset().filter(
            models.Q(full_name__icontains=query)
            | models.Q(mobile__icontains=query)
            | models.Q(email__icontains=query)
        )
