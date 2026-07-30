from repositories.base import BaseRepository
from apps.tasks.models import Task


class TaskRepository(BaseRepository):
    model = Task
