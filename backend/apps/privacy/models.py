from django.conf import settings
from django.db import models

from core.base_models import BaseModel


class PrivacyRequest(BaseModel):
    """A data-protection request submitted by a user or data subject.

    Tenant/user links are optional so anonymous data subjects can still file a
    request; they are only populated when the requester can be matched.
    """

    class RequestType(models.TextChoices):
        ACCESS = "ACCESS", "Access / copy of my data"
        RECTIFICATION = "RECTIFICATION", "Correction of my data"
        ERASURE = "ERASURE", "Deletion of my data"
        PORTABILITY = "PORTABILITY", "Export of my data"
        RESTRICTION = "RESTRICTION", "Restriction of processing"
        OBJECTION = "OBJECTION", "Objection to processing"
        ACCOUNT_CLOSURE = "ACCOUNT_CLOSURE", "Account closure"
        OTHER = "OTHER", "Other privacy question"

    class Status(models.TextChoices):
        SUBMITTED = "SUBMITTED", "Submitted"
        IN_REVIEW = "IN_REVIEW", "In review"
        ACTIONED = "ACTIONED", "Completed"
        REJECTED = "REJECTED", "Declined"
        CLOSED = "CLOSED", "Closed"

    email = models.EmailField()
    full_name = models.CharField(max_length=255, blank=True)
    request_type = models.CharField(
        max_length=32, choices=RequestType.choices, default=RequestType.OTHER
    )
    description = models.TextField(blank=True)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.SUBMITTED, db_index=True
    )
    admin_notes = models.TextField(blank=True)
    responded_at = models.DateTimeField(null=True, blank=True)
    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_index=True,
        related_name="privacy_requests",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        db_index=True,
        related_name="privacy_requests",
    )
    ip_address = models.GenericIPAddressField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["email", "created_at"])]

    def __str__(self):
        return f"{self.request_type} / {self.email} / {self.status}"


class ContactMessage(BaseModel):
    """A message submitted through a public website form.

    Stores the submission (including explicit consent flags) so the business can
    act on it; the same content is emailed to the configured support inbox.
    """

    class Source(models.TextChoices):
        CONTACT = "contact", "Contact form"
        DEMO = "demo", "Demo request"
        CAREERS = "careers", "Careers"
        STATUS = "status", "Status updates"

    source = models.CharField(max_length=16, choices=Source.choices, default=Source.CONTACT)
    name = models.CharField(max_length=255)
    email = models.EmailField()
    company = models.CharField(max_length=255, blank=True)
    phone = models.CharField(max_length=32, blank=True)
    subject = models.CharField(max_length=255, blank=True)
    message = models.TextField()
    privacy_acknowledged = models.BooleanField(default=False)
    marketing_opt_in = models.BooleanField(default=False)
    resume = models.FileField(
        upload_to="contact/resumes/%Y/%m/",
        null=True,
        blank=True,
        max_length=500,
    )
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    is_handled = models.BooleanField(default=False, db_index=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["source", "created_at"])]

    def __str__(self):
        return f"{self.source} / {self.email} / {self.created_at:%Y-%m-%d}"
