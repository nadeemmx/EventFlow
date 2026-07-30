from repositories.base import BaseRepository
from apps.packages.models import Package, PackageItem


class PackageRepository(BaseRepository):
    model = Package


class PackageItemRepository(BaseRepository):
    model = PackageItem
