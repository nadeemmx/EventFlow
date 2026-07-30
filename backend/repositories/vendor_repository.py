from repositories.base import BaseRepository
from apps.vendors.models import Vendor, BookingVendor


class VendorRepository(BaseRepository):
    model = Vendor


class BookingVendorRepository(BaseRepository):
    model = BookingVendor
