from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas


def generate_invoice_pdf(invoice, filepath):
    c = canvas.Canvas(filepath, pagesize=A4)
    width, height = A4
    c.setFont("Helvetica-Bold", 16)
    c.drawString(50, height - 50, f"Invoice: {invoice.invoice_number}")
    c.setFont("Helvetica", 12)
    c.drawString(50, height - 80, f"Date: {invoice.invoice_date}")
    c.drawString(50, height - 100, f"Booking: {invoice.booking.booking_number}")
    c.drawString(50, height - 120, f"Customer: {invoice.booking.customer.full_name}")
    c.drawString(50, height - 150, "-" * 50)
    c.drawString(50, height - 170, f"Subtotal: {invoice.subtotal}")
    c.drawString(50, height - 190, f"Tax: {invoice.tax_amount}")
    c.setFont("Helvetica-Bold", 14)
    c.drawString(50, height - 220, f"Total: {invoice.total_amount}")
    c.save()
    return filepath


def generate_receipt_pdf(payment, filepath):
    c = canvas.Canvas(filepath, pagesize=A4)
    width, height = A4
    c.setFont("Helvetica-Bold", 16)
    c.drawString(50, height - 50, "Payment Receipt")
    c.setFont("Helvetica", 12)
    c.drawString(50, height - 80, f"Amount: {payment.amount}")
    c.drawString(50, height - 100, f"Method: {payment.payment_method}")
    c.drawString(50, height - 120, f"Date: {payment.payment_date}")
    c.save()
    return filepath
