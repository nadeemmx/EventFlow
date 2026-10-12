from django.utils import timezone


def generate_invoice_number(prefix="INV"):
    """Next sequential invoice number for the current year, e.g. INV-2026-000001.

    Hardened against legacy rows: ``invoice_number`` historically defaulted to
    an empty string, and any row whose tail is not numeric would otherwise make
    ``int()`` raise and 500 the create it was meant to prevent.
    """
    year = timezone.now().year
    prefix_year = f"{prefix}-{year}"
    from apps.invoices.models import Invoice
    last_num = 0
    for invoice in Invoice.objects.filter(
        invoice_number__startswith=prefix_year
    ).order_by("-invoice_number"):
        tail = invoice.invoice_number.rsplit("-", 1)[-1]
        if tail.isdigit():
            last_num = int(tail)
            break
    return f"{prefix_year}-{last_num + 1:06d}"
