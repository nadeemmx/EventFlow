from django.db import transaction
from django.db.models import Sum
from repositories.payment_repository import PaymentRepository
from repositories.booking_repository import BookingRepository
from repositories.audit_repository import AuditRepository
from services.base import BaseService
from core.choices import PaymentType, PaymentStatus, BookingStatus
from core.exceptions import ValidationException
from django.utils import timezone


class PaymentService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = PaymentRepository(self.tenant, self.user)
        self.booking_repo = BookingRepository(self.tenant, self.user)
        self.audit_repo = AuditRepository(self.tenant, self.user)

    def get_repository(self):
        return self.repo

    @transaction.atomic
    def create_payment(self, data):
        booking = self.booking_repo.get_for_update(data["booking_id"])
        amount = data["amount"]
        total_paid = self.repo.get_total_paid(booking)
        outstanding = booking.total_amount - total_paid
        if amount > outstanding:
            raise ValidationException("Payment exceeds outstanding balance")
        payment = self.repo.create(
            booking=booking,
            amount=amount,
            payment_method=data.get("payment_method", "CASH"),
            payment_date=data.get("payment_date"),
            notes=data.get("notes", ""),
        )
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="PAYMENTS", action="CREATE",
            record_id=payment.id,
        )
        from services.booking_service import BookingService
        bk_service = BookingService(self.tenant, self.user)
        bk_service.update_booking_status_from_payments(booking)
        return payment

    @transaction.atomic
    def refund_payment(self, payment_id):
        payment = self.repo.get_for_update(payment_id)
        if payment.payment_type == PaymentType.REFUND:
            raise ValidationException("Payment already refunded")
        booking = payment.booking
        if booking.status not in ["CANCELLED", "REFUNDED"]:
            raise ValidationException("Refund only allowed for cancelled bookings")
        refund = self.repo.create(
            booking=booking,
            amount=payment.amount,
            payment_method=payment.payment_method,
            payment_type=PaymentType.REFUND,
            payment_date=timezone.now().date(),
            notes=f"Refund of payment {payment.id}",
        )
        self.audit_repo.log(
            tenant=self.tenant, user=self.user,
            module="PAYMENTS", action="REFUND",
            record_id=refund.id,
        )
        booking.status = BookingStatus.REFUNDED
        booking.save(update_fields=["status"])
        return refund

    def get_outstanding(self, booking_id):
        booking = self.booking_repo.get_by_id(booking_id)
        total_paid = self.repo.get_total_paid(booking)
        total_refunded = self.repo.get_total_refunded(booking)
        return {
            "booking_id": booking.id,
            "booking_number": booking.booking_number,
            "total_amount": booking.total_amount,
            "total_paid": total_paid,
            "total_refunded": total_refunded,
            "outstanding": booking.total_amount - total_paid,
            "payment_status": "PAID" if total_paid >= booking.total_amount else ("PARTIAL" if total_paid > 0 else "PENDING"),
        }

    def get_payment_summary(self, start_date=None, end_date=None):
        qs = self.repo.get_queryset()
        if start_date:
            qs = qs.filter(payment_date__gte=start_date)
        if end_date:
            qs = qs.filter(payment_date__lte=end_date)
        payments = qs.filter(payment_type="PAYMENT")
        refunds = qs.filter(payment_type="REFUND")
        total_collected = payments.aggregate(total=Sum("amount"))["total"] or 0
        total_refunded = refunds.aggregate(total=Sum("amount"))["total"] or 0
        by_method = dict(payments.values_list("payment_method").annotate(total=Sum("amount")))
        return {
            "total_collected": total_collected,
            "total_refunded": total_refunded,
            "net_revenue": total_collected - total_refunded,
            "by_method": by_method,
        }

    def create_razorpay_order(self, booking_id, amount=None):
        from gateway.payments.razorpay import RazorpayGateway
        from apps.settings.models import PaymentGatewaySettings
        booking = self.booking_repo.get_by_id(booking_id)
        pay_amount = amount if amount else booking.total_amount - self.repo.get_total_paid(booking)
        if pay_amount <= 0:
            raise ValidationException("No outstanding balance")
        settings = PaymentGatewaySettings.objects.filter(
            tenant=booking.tenant, gateway="RAZORPAY", is_active=True
        ).first()
        if not settings:
            raise ValidationException("Razorpay not configured for this tenant")
        gateway = RazorpayGateway(settings.api_key, settings.api_secret)
        order = gateway.create_payment(
            amount=pay_amount,
            currency="INR",
            description=f"Booking {booking.booking_number}",
            metadata={"booking_id": str(booking.id), "tenant_id": str(self.tenant.id)},
        )
        return order

    def verify_razorpay_payment(self, order_id, payment_id, signature, booking_id=None):
        from gateway.payments.razorpay import RazorpayGateway
        from apps.settings.models import PaymentGatewaySettings
        settings = PaymentGatewaySettings.objects.filter(
            gateway="RAZORPAY", is_active=True
        ).first()
        if not settings:
            raise ValidationException("Razorpay not configured")
        gateway = RazorpayGateway(settings.api_key, settings.api_secret)
        result = gateway.verify_payment(order_id, payment_id, signature)
        if not result.get("verified"):
            raise ValidationException("Payment verification failed")
        if not booking_id:
            raise ValidationException("booking_id is required for verification")
        booking = self.booking_repo.get_for_update(booking_id)
        payment = self.repo.create(
            booking=booking,
            amount=0,
            payment_method="RAZORPAY",
            transaction_reference=payment_id,
            payment_date=timezone.now().date(),
        )
        return {"verified": True, "payment_id": payment_id, "payment_id_db": payment.id}

    def generate_receipt_pdf(self, payment):
        from io import BytesIO
        from reportlab.lib.pagesizes import A4
        from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
        from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
        from reportlab.lib.colors import HexColor
        from reportlab.lib.units import mm
        from reportlab.lib import colors

        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4, topMargin=20*mm, bottomMargin=20*mm)

        styles = getSampleStyleSheet()
        elements = []

        title_style = ParagraphStyle("Title2", parent=styles["Title"], fontSize=22, textColor=colors.HexColor("#0F172A"), spaceAfter=4)
        elements.append(Paragraph("PAYMENT RECEIPT", title_style))
        elements.append(Spacer(1, 6))

        info_style = ParagraphStyle("Info", parent=styles["Normal"], fontSize=10, textColor=colors.HexColor("#475569"))
        elements.append(Paragraph(f"Receipt #: {payment.id}", info_style))
        elements.append(Paragraph(f"Date: {payment.payment_date.strftime('%d %b %Y')}", info_style))
        elements.append(Paragraph(f"Booking #: {payment.booking.booking_number}", info_style))
        elements.append(Spacer(1, 12))

        elements.append(Paragraph("<b>Customer:</b>", styles["Heading4"]))
        elements.append(Paragraph(f"{payment.booking.customer.full_name}", info_style))
        elements.append(Spacer(1, 12))

        table_data = [
            ["Description", "Amount (₹)"],
            [f"Payment via {payment.get_payment_method_display()}", f"{payment.amount:,.2f}"],
            ["<b>Total Paid</b>", f"<b>{payment.amount:,.2f}</b>"],
        ]

        table = Table(table_data, colWidths=[350, 150])
        table.setStyle(TableStyle([
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("FONTSIZE", (0, 0), (-1, 0), 10),
            ("FONTSIZE", (0, 1), (-1, -1), 10),
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

        doc.build(elements)
        pdf = buffer.getvalue()
        buffer.close()
        return pdf
