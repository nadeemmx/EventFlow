from repositories.base import BaseRepository
from apps.leads.models import Lead, FollowUp, Quotation, QuotationItem


class LeadRepository(BaseRepository):
    model = Lead


class FollowUpRepository(BaseRepository):
    model = FollowUp


class QuotationRepository(BaseRepository):
    model = Quotation


class QuotationItemRepository(BaseRepository):
    model = QuotationItem
