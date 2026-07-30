from django.db import models, transaction
from django.core.paginator import Paginator, EmptyPage
from django.utils.timezone import now
from core.constants import DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE
from core.exceptions import NotFoundException


class BaseRepository:
    model = None

    def __init__(self, tenant=None, user=None):
        self.tenant = tenant
        self.user = user

    def get_queryset(self):
        qs = self.model.objects.all()
        if self.tenant and hasattr(self.model, "tenant"):
            qs = qs.filter(tenant=self.tenant)
        if hasattr(self.model, "is_deleted"):
            qs = qs.filter(is_deleted=False)
        return qs

    def get_for_update(self, id):
        try:
            return self.get_queryset().select_for_update().get(id=id)
        except self.model.DoesNotExist:
            raise NotFoundException(f"{self.model.__name__} not found")

    def get_by_id(self, id):
        try:
            return self.get_queryset().get(id=id)
        except self.model.DoesNotExist:
            raise NotFoundException(f"{self.model.__name__} not found")

    def list(self, page=1, page_size=DEFAULT_PAGE_SIZE, filters=None, ordering=None):
        qs = self.get_queryset()
        if filters:
            qs = qs.filter(**filters)
        if ordering:
            qs = qs.order_by(ordering)
        else:
            qs = qs.order_by("-created_at")
        page_size = min(page_size, MAX_PAGE_SIZE)
        paginator = Paginator(qs, page_size)
        try:
            page_obj = paginator.page(page)
        except EmptyPage:
            page_obj = paginator.page(paginator.num_pages)
        return page_obj

    def create(self, **kwargs):
        if self.tenant and "tenant" not in kwargs and hasattr(self.model, "tenant"):
            kwargs["tenant"] = self.tenant
        if self.user and "created_by" not in kwargs and hasattr(self.model, "created_by"):
            kwargs["created_by"] = self.user
        return self.model.objects.create(**kwargs)

    @transaction.atomic
    def update(self, instance, **kwargs):
        for field, value in kwargs.items():
            setattr(instance, field, value)
        if self.user and hasattr(instance, "updated_by"):
            instance.updated_by = self.user
        instance.save()
        return instance

    @transaction.atomic
    def delete(self, instance):
        if hasattr(instance, "is_deleted"):
            instance.is_deleted = True
            instance.deleted_at = now()
            if self.user:
                instance.deleted_by = self.user
            instance.save()
        else:
            instance.delete()

    def count(self, filters=None):
        qs = self.get_queryset()
        if filters:
            qs = qs.filter(**filters)
        return qs.count()
