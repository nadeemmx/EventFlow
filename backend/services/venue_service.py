from repositories.venue_repository import VenueRepository, VenueImageRepository
from repositories.audit_repository import AuditRepository
from services.base import BaseService
from core.choices import VenueStatus
from core.exceptions import ValidationException, ConflictException
from core.constants import MAX_VENUE_IMAGES


class VenueService(BaseService):
    def __init__(self, tenant=None, user=None):
        super().__init__(tenant, user)
        self.repo = VenueRepository(self.tenant, self.user)
        self.image_repo = VenueImageRepository(self.tenant, self.user)
        self.audit_repo = AuditRepository(self.tenant, self.user)

    def get_repository(self):
        return self.repo

    def create_venue(self, data):
        return self.repo.create(**data)

    def add_image(self, venue_id, image):
        venue = self.repo.get_by_id(venue_id)
        image_count = self.image_repo.get_venue_images(venue).count()
        if image_count >= MAX_VENUE_IMAGES:
            raise ValidationException(f"Maximum {MAX_VENUE_IMAGES} images allowed per venue")
        return self.image_repo.create(
            venue=venue,
            image=image,
            display_order=image_count + 1,
        )

    def delete_image(self, image_id):
        image = self.image_repo.get_by_id(image_id)
        self.image_repo.delete(image)
