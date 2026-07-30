from django.db import models


class TenantStatus(models.TextChoices):
    ACTIVE = "ACTIVE", "Active"
    INACTIVE = "INACTIVE", "Inactive"
    SUSPENDED = "SUSPENDED", "Suspended"
    EXPIRED = "EXPIRED", "Expired"
    TRIAL = "TRIAL", "Trial"


class UserRole(models.TextChoices):
    SUPER_ADMIN = "SUPER_ADMIN", "Super Admin"
    OWNER = "OWNER", "Owner"
    MANAGER = "MANAGER", "Manager"
    ACCOUNTANT = "ACCOUNTANT", "Accountant"
    STAFF = "STAFF", "Staff"
    CUSTOMER = "CUSTOMER", "Customer"


class VenueType(models.TextChoices):
    MARRIAGE_LAWN = "MARRIAGE_LAWN", "Marriage Lawn"
    BANQUET_HALL = "BANQUET_HALL", "Banquet Hall"
    CONVENTION_CENTER = "CONVENTION_CENTER", "Convention Center"
    PARTY_PLOT = "PARTY_PLOT", "Party Plot"
    RESORT = "RESORT", "Resort"


class VenueStatus(models.TextChoices):
    ACTIVE = "ACTIVE", "Active"
    INACTIVE = "INACTIVE", "Inactive"
    MAINTENANCE = "MAINTENANCE", "Maintenance"


class EventType(models.TextChoices):
    WEDDING = "WEDDING", "Wedding"
    RECEPTION = "RECEPTION", "Reception"
    WALIMA = "WALIMA", "Walima"
    BIRTHDAY = "BIRTHDAY", "Birthday"
    ENGAGEMENT = "ENGAGEMENT", "Engagement"
    CORPORATE = "CORPORATE", "Corporate Event"
    CONFERENCE = "CONFERENCE", "Conference"
    EXHIBITION = "EXHIBITION", "Exhibition"
    RELIGIOUS = "RELIGIOUS", "Religious Event"
    CUSTOM = "CUSTOM", "Custom Event"


class LeadStatus(models.TextChoices):
    NEW = "NEW", "New"
    CONTACTED = "CONTACTED", "Contacted"
    SITE_VISIT = "SITE_VISIT", "Site Visit"
    NEGOTIATION = "NEGOTIATION", "Negotiation"
    QUOTATION_SENT = "QUOTATION_SENT", "Quotation Sent"
    ADVANCE_RECEIVED = "ADVANCE_RECEIVED", "Advance Received"
    CONVERTED = "CONVERTED", "Converted"
    LOST = "LOST", "Lost"


class LeadSource(models.TextChoices):
    WEBSITE = "WEBSITE", "Website"
    GOOGLE = "GOOGLE", "Google"
    FACEBOOK = "FACEBOOK", "Facebook"
    INSTAGRAM = "INSTAGRAM", "Instagram"
    WHATSAPP = "WHATSAPP", "WhatsApp"
    WALK_IN = "WALK_IN", "Walk In"
    REFERRAL = "REFERRAL", "Referral"


class BookingStatus(models.TextChoices):
    DRAFT = "DRAFT", "Draft"
    TENTATIVE = "TENTATIVE", "Tentative"
    CONFIRMED = "CONFIRMED", "Confirmed"
    IN_PROGRESS = "IN_PROGRESS", "In Progress"
    COMPLETED = "COMPLETED", "Completed"
    CANCELLED = "CANCELLED", "Cancelled"
    REFUNDED = "REFUNDED", "Refunded"


class PaymentMethod(models.TextChoices):
    CASH = "CASH", "Cash"
    UPI = "UPI", "UPI"
    BANK_TRANSFER = "BANK_TRANSFER", "Bank Transfer"
    CHEQUE = "CHEQUE", "Cheque"
    CARD = "CARD", "Card"
    RAZORPAY = "RAZORPAY", "Razorpay"


class PaymentType(models.TextChoices):
    PAYMENT = "PAYMENT", "Payment"
    REFUND = "REFUND", "Refund"


class PaymentStatus(models.TextChoices):
    PENDING = "PENDING", "Pending"
    PARTIAL = "PARTIAL", "Partial"
    PAID = "PAID", "Paid"
    OVERDUE = "OVERDUE", "Overdue"


class VendorType(models.TextChoices):
    CATERER = "CATERER", "Caterer"
    DECORATOR = "DECORATOR", "Decorator"
    DJ = "DJ", "DJ"
    PHOTOGRAPHER = "PHOTOGRAPHER", "Photographer"
    VIDEOGRAPHER = "VIDEOGRAPHER", "Videographer"
    SECURITY = "SECURITY", "Security"
    CLEANING = "CLEANING", "Cleaning"
    OTHER = "OTHER", "Other"


class VendorStatus(models.TextChoices):
    ACTIVE = "ACTIVE", "Active"
    INACTIVE = "INACTIVE", "Inactive"


class InventoryCategory(models.TextChoices):
    CHAIRS = "CHAIRS", "Chairs"
    TABLES = "TABLES", "Tables"
    STAGE = "STAGE", "Stage"
    LIGHTS = "LIGHTS", "Lights"
    GENERATOR = "GENERATOR", "Generator"
    SOUND_SYSTEM = "SOUND_SYSTEM", "Sound System"
    DECORATION = "DECORATION", "Decoration"


class StaffStatus(models.TextChoices):
    ACTIVE = "ACTIVE", "Active"
    INACTIVE = "INACTIVE", "Inactive"
    ON_LEAVE = "ON_LEAVE", "On Leave"


class TaskPriority(models.TextChoices):
    LOW = "LOW", "Low"
    MEDIUM = "MEDIUM", "Medium"
    HIGH = "HIGH", "High"
    URGENT = "URGENT", "Urgent"


class TaskStatus(models.TextChoices):
    OPEN = "OPEN", "Open"
    IN_PROGRESS = "IN_PROGRESS", "In Progress"
    COMPLETED = "COMPLETED", "Completed"
    CANCELLED = "CANCELLED", "Cancelled"


class SubscriptionPlanName(models.TextChoices):
    STARTER = "STARTER", "Starter"
    PROFESSIONAL = "PROFESSIONAL", "Professional"
    ENTERPRISE = "ENTERPRISE", "Enterprise"


class BillingCycle(models.TextChoices):
    MONTHLY = "MONTHLY", "Monthly"
    QUARTERLY = "QUARTERLY", "Quarterly"
    YEARLY = "YEARLY", "Yearly"


class SubscriptionStatus(models.TextChoices):
    TRIAL = "TRIAL", "Trial"
    ACTIVE = "ACTIVE", "Active"
    EXPIRED = "EXPIRED", "Expired"
    CANCELLED = "CANCELLED", "Cancelled"
    SUSPENDED = "SUSPENDED", "Suspended"


class NotificationChannel(models.TextChoices):
    EMAIL = "EMAIL", "Email"
    WHATSAPP = "WHATSAPP", "WhatsApp"
    IN_APP = "IN_APP", "In App"


class NotificationStatus(models.TextChoices):
    PENDING = "PENDING", "Pending"
    SENT = "SENT", "Sent"
    FAILED = "FAILED", "Failed"


class PaymentGateway(models.TextChoices):
    RAZORPAY = "RAZORPAY", "Razorpay"
    STRIPE = "STRIPE", "Stripe"
    PAYTM = "PAYTM", "Paytm"
    CASH = "CASH", "Cash"
    BANK_TRANSFER = "BANK_TRANSFER", "Bank Transfer"


class QuotationStatus(models.TextChoices):
    DRAFT = "DRAFT", "Draft"
    SENT = "SENT", "Sent"
    ACCEPTED = "ACCEPTED", "Accepted"
    REJECTED = "REJECTED", "Rejected"
    EXPIRED = "EXPIRED", "Expired"
