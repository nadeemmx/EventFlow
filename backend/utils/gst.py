from decimal import Decimal, ROUND_HALF_UP


def calculate_gst(amount: Decimal, rate: Decimal):
    tax = (amount * rate / Decimal("100")).quantize(
        Decimal("0.01"), rounding=ROUND_HALF_UP
    )
    return {
        "cgst": tax / Decimal("2"),
        "sgst": tax / Decimal("2"),
        "igst": tax,
        "total_tax": tax,
    }
