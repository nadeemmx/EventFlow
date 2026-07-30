from decimal import Decimal
from django.db import transaction, IntegrityError
from repositories.invoice_repository import InvoiceRepository
from repositories.booking_repository import BookingRepository
from repositories.audit_repository import AuditRepository
from services.base import BaseService
from core.exceptions import ValidationException
from utils.invoice_numbers import generate_invoice_number
from utils.money import calculate_gst


class InvoiceService(BaseService):
    MAX_INVOICE_RETRIES = 5

    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = InvoiceRepository(self.tenant, self.user)
        self.booking_repo = BookingRepository(self.tenant, self.user)
        self.audit_repo = AuditRepository(self.tenant, self.user)

    def get_repository(self):
        return self.repo

    @transaction.atomic
    def generate_invoice(self, booking_id):
        booking = self.booking_repo.get_for_update(booking_id)
        existing = self.repo.get_queryset().filter(booking=booking).first()
        if existing:
            raise ValidationException("Invoice already exists for this booking")
        tenant_settings = booking.tenant.settings if hasattr(booking.tenant, "settings") else None
        gst_rate = Decimal(str(tenant_settings.gst_rate)) if tenant_settings else Decimal("18.00")
        tax_info = calculate_gst(booking.total_amount, gst_rate)
        for attempt in range(self.MAX_INVOICE_RETRIES):
            try:
                invoice = self.repo.create(
                    tenant=self.tenant,
                    booking=booking,
                    invoice_number=generate_invoice_number(),
                    invoice_date=booking.event_date,
                    subtotal=booking.total_amount,
                    tax_amount=tax_info["total_tax"],
                    total_amount=booking.total_amount + tax_info["total_tax"],
                )
                break
            except IntegrityError:
                if attempt == self.MAX_INVOICE_RETRIES - 1:
                    raise ValidationException("Failed to generate unique invoice number, please retry")
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="INVOICES", action="GENERATE",
            record_id=invoice.id,
        )
        return invoice

    def generate_pdf(self, invoice):
        from io import BytesIO
        from reportlab.lib.pagesizes import A4
        from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.lib.colors import HexColor
        from reportlab.lib.units import mm, inch
        from reportlab.lib import colors
        from datetime import datetime

        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4, topMargin=20*mm, bottomMargin=20*mm)

        styles = getSampleStyleSheet()
        elements = []

        tenant = invoice.booking.tenant
        business_name = tenant.business_name if tenant else "Business Name"

        title_style = ParagraphStyle("Title2", parent=styles["Title"], fontSize=22, textColor=colors.HexColor("#0F172A"), spaceAfter=4)
        elements.append(Paragraph("INVOICE", title_style))
        elements.append(Spacer(1, 6))

        info_style = ParagraphStyle("Info", parent=styles["Normal"], fontSize=10, textColor=colors.HexColor("#475569"))
        elements.append(Paragraph(f"Invoice #: {invoice.invoice_number}", info_style))
        elements.append(Paragraph(f"Date: {invoice.invoice_date.strftime('%d %b %Y')}", info_style))
        elements.append(Paragraph(f"Booking #: {invoice.booking.booking_number}", info_style))
        elements.append(Spacer(1, 12))

        elements.append(Paragraph("<b>Bill To:</b>", styles["Heading4"]))
        elements.append(Paragraph(f"{invoice.booking.customer.full_name}", info_style))
        if invoice.booking.customer.email:
            elements.append(Paragraph(f"Email: {invoice.booking.customer.email}", info_style))
        if invoice.booking.customer.mobile:
            elements.append(Paragraph(f"Phone: {invoice.booking.customer.mobile}", info_style))
        elements.append(Spacer(1, 12))

        elements.append(Paragraph(f"<b>Event:</b> {invoice.booking.event_type.replace('_', ' ').title()}", info_style))
        elements.append(Paragraph(f"<b>Date:</b> {invoice.booking.event_date.strftime('%d %b %Y')}", info_style))
        elements.append(Paragraph(f"<b>Venue:</b> {invoice.booking.venue.name}", info_style))
        elements.append(Spacer(1, 16))

        table_data = [
            ["Description", "Amount (₹)"],
            ["Event Package & Services", f"{invoice.subtotal:,.2f}"],
        ]
        if invoice.tax_amount > 0:
            table_data.append(["GST @ 18%", f"{invoice.tax_amount:,.2f}"])
        table_data.append(["<b>Total Amount</b>", f"<b>{invoice.total_amount:,.2f}</b>"])

        table = Table(table_data, colWidths=[350, 150])
        table.setStyle(TableStyle([
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("FONTSIZE", (0, 0), (-1, 0), 10),
            ("FONTNAME", (0, 1), (-1, -2), "Helvetica"),
            ("FONTSIZE", (0, 1), (-1, -2), 10),
            ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
            ("FONTSIZE", (0, -1), (-1, -1), 12),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#0F172A")),
            ("TEXTCOLOR", (0, -1), (-1, -1), colors.HexColor("#0F172A")),
            ("ALIGN", (1, 0), (-1, -1), "RIGHT"),
            ("GRID", (0, 0), (-1, -2), 0.5, colors.HexColor("#E2E8F0")),
            ("LINEBELOW", (0, -1), (-1, -1), 2, colors.HexColor("#0F172A")),
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#F8FAFC")),
            ("TOPPADDING", (0, 0), (-1, -1), 8),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
        ]))
        elements.append(table)
        elements.append(Spacer(1, 20))

        terms_style = ParagraphStyle("Terms", parent=styles["Normal"], fontSize=8, textColor=colors.HexColor("#94A3B8"))
        elements.append(Paragraph("<b>Terms & Conditions:</b>", terms_style))
        elements.append(Paragraph("1. Payment is due within 7 days of invoice date.", terms_style))
        elements.append(Paragraph("2. Late payments may incur additional charges.", terms_style))
        elements.append(Paragraph("3. This is a computer-generated invoice.", terms_style))

        doc.build(elements)
        pdf = buffer.getvalue()
        buffer.close()

        from django.core.files.base import ContentFile
        invoice.pdf_file.save(f"{invoice.invoice_number}.pdf", ContentFile(pdf), save=True)

        return pdf

    def email_invoice(self, invoice_id):
        invoice = self.repo.get_by_id(invoice_id)
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="INVOICES", action="EMAIL",
            record_id=invoice.id,
        )
        return True
