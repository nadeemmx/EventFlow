from repositories.base import BaseRepository
from apps.staff.models import Staff


class StaffRepository(BaseRepository):
    model = Staff
