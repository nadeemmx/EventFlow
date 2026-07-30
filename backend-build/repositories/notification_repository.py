from repositories.base import BaseRepository
from apps.notifications.models import Notification


class NotificationRepository(BaseRepository):
    model = Notification
