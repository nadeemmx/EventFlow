from django.db import models
from core.base_models import TenantBaseModel
from core.validators import validate_pdf_file

class Contract(TenantBaseModel):
    CONTRACT_STATUS = [
        ("DRAFT", "Draft"),
        ("SENT", "Sent"),
        ("SIGNED", "Signed"),
        ("EXPIRED", "Expired"),
        ("CANCELLED", "Cancelled"),
    ]
    booking = models.ForeignKey("bookings.Booking", on_delete=models.CASCADE, related_name="contracts", db_index=True)
    contract_number = models.CharField(max_length=50, unique=True, db_index=True)
    content = models.TextField(blank=True)
    status = models.CharField(max_length=30, choices=CONTRACT_STATUS, default="DRAFT", db_index=True)
    pdf_file = models.FileField(upload_to="contracts/pdf/", blank=True, validators=[validate_pdf_file])
    valid_from = models.DateField(null=True, blank=True)
    valid_until = models.DateField(null=True, blank=True)
    signed_date = models.DateTimeField(null=True, blank=True)
    signed_by_name = models.CharField(max_length=255, blank=True)
    signed_by_designation = models.CharField(max_length=255, blank=True)
    template_version = models.CharField(max_length=20, default="1.0")
    notes = models.TextField(blank=True)

    class Meta:
        db_table = "contracts"
        verbose_name = "Contract"
        verbose_name_plural = "Contracts"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["tenant", "status"]),
            models.Index(fields=["tenant", "created_at"]),
        ]

    def __str__(self):
        return self.contract_number
