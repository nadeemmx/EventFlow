from decimal import Decimal, ROUND_HALF_UP


def format_inr(amount: Decimal) -> str:
    if amount is None:
        return "₹0.00"
    amount = amount.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
    return f"₹{amount:,.2f}"


def calculate_gst(amount: Decimal, rate: Decimal = Decimal("18.00")):
    tax = (amount * rate / Decimal("100")).quantize(
        Decimal("0.01"), rounding=ROUND_HALF_UP
    )
    cgst = tax / Decimal("2")
    sgst = tax / Decimal("2")
    return {
        "cgst": cgst,
        "sgst": sgst,
        "igst": tax,
        "total_tax": tax,
    }
