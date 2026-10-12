from rest_framework import serializers
from apps.invoices.models import Invoice
from utils.invoice_numbers import generate_invoice_number


class InvoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Invoice
        fields = [
            "id", "booking", "invoice_number", "invoice_date",
            "subtotal", "tax_amount", "total_amount",
            "pdf_file", "created_at",
        ]
        read_only_fields = ["id", "invoice_number", "created_at"]

    def create(self, validated_data):
        # ``invoice_number`` is read-only and has no model default, so a direct
        # POST /invoices/ used to write "" — and the unique constraint then
        # rejected the *second* create with an IntegrityError 500. Generate a
        # real number here (the generate action already did via InvoiceService).
        validated_data["invoice_number"] = generate_invoice_number()
        return super().create(validated_data)


class GenerateInvoiceSerializer(serializers.Serializer):
    booking_id = serializers.IntegerField()
