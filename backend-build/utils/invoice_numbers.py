from django.utils import timezone


def generate_invoice_number(prefix="INV"):
    year = timezone.now().year
    from apps.invoices.models import Invoice
    last = Invoice.objects.filter(
        invoice_number__startswith=f"{prefix}-{year}"
    ).order_by("invoice_number").last()
    if last:
        last_num = int(last.invoice_number.split("-")[-1])
        new_num = last_num + 1
    else:
        new_num = 1
    return f"{prefix}-{year}-{new_num:06d}"
