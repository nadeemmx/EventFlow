from repositories.base import BaseRepository
from apps.invoices.models import Invoice


class InvoiceRepository(BaseRepository):
    model = Invoice
