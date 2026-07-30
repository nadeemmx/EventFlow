from repositories.base import BaseRepository
from apps.leads.models import Lead, FollowUp, Quotation


class LeadRepository(BaseRepository):
    model = Lead


class FollowUpRepository(BaseRepository):
    model = FollowUp


class QuotationRepository(BaseRepository):
    model = Quotation
