from rest_framework import serializers
from apps.invoices.models import Invoice


class InvoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Invoice
        fields = [
            "id", "booking", "invoice_number", "invoice_date",
            "subtotal", "tax_amount", "total_amount",
            "pdf_file", "created_at",
        ]
        read_only_fields = ["id", "invoice_number", "created_at"]


class GenerateInvoiceSerializer(serializers.Serializer):
    booking_id = serializers.IntegerField()
