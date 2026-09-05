from django.db import models
from core.base_models import TenantBaseModel
from core.validators import validate_pdf_file


class Invoice(TenantBaseModel):
    booking = models.ForeignKey(
        "bookings.Booking", on_delete=models.CASCADE, related_name="invoices", db_index=True
    )
    invoice_number = models.CharField(max_length=100, unique=True, db_index=True)
    invoice_date = models.DateField(db_index=True)
    subtotal = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    tax_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    pdf_file = models.FileField(upload_to="invoices/pdf/", blank=True, validators=[validate_pdf_file])

    class Meta:
        db_table = "invoices"
        verbose_name = "Invoice"
        verbose_name_plural = "Invoices"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["tenant", "invoice_date"]),
            models.Index(fields=["tenant", "created_at"]),
        ]

    def __str__(self):
        return self.invoice_number
