from repositories.base import BaseRepository
from apps.contracts.models import Contract

class ContractRepository(BaseRepository):
    model = Contract
