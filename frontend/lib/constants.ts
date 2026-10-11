export const BOOKING_STATUSES = [
  "DRAFT", "TENTATIVE", "CONFIRMED", "IN_PROGRESS", "COMPLETED", "CANCELLED", "REFUNDED",
] as const;

export const CONTRACT_STATUSES = ["DRAFT", "SENT", "SIGNED", "EXPIRED", "CANCELLED"] as const;

export const QUOTATION_STATUSES = ["DRAFT", "SENT", "ACCEPTED", "REJECTED", "EXPIRED"] as const;

export const EVENT_TYPES = [
  "WEDDING", "RECEPTION", "WALIMA", "BIRTHDAY", "ENGAGEMENT",
  "CORPORATE", "CONFERENCE", "EXHIBITION", "RELIGIOUS", "CUSTOM",
] as const;

export const USER_ROLES = [
  "SUPER_ADMIN", "OWNER", "MANAGER", "ACCOUNTANT", "STAFF", "CUSTOMER",
] as const;

export const PAYMENT_METHODS = [
  "CASH", "UPI", "BANK_TRANSFER", "CHEQUE", "CARD",
] as const;

export const VENUE_TYPES = [
  "MARRIAGE_LAWN", "BANQUET_HALL", "CONVENTION_CENTER", "PARTY_PLOT", "RESORT",
] as const;

export const LEAD_STATUSES = [
  "NEW", "CONTACTED", "SITE_VISIT", "NEGOTIATION",
  "QUOTATION_SENT", "ADVANCE_RECEIVED", "CONVERTED", "LOST",
] as const;

export const STATUS_COLORS: Record<string, string> = {
  DRAFT: "bg-warm-200 text-jetBlack-600",
  TENTATIVE: "bg-gold-100 text-gold-800",
  CONFIRMED: "bg-success/10 text-success",
  COMPLETED: "bg-primary/10 text-gold-700",
  CANCELLED: "bg-destructive/10 text-destructive",
  REFUNDED: "bg-warm-200 text-jetBlack-600",
  SENT: "bg-blue-100 text-blue-800",
  ACCEPTED: "bg-green-100 text-green-800",
  REJECTED: "bg-destructive/10 text-destructive",
  SIGNED: "bg-success/10 text-success",
  EXPIRED: "bg-warm-200 text-jetBlack-600",
  ACTIVE: "bg-success/10 text-success",
  INACTIVE: "bg-warm-200 text-jetBlack-600",
  IN_STOCK: "bg-success/10 text-success",
  LOW_STOCK: "bg-amber-100 text-amber-800",
  OUT_OF_STOCK: "bg-destructive/10 text-destructive",
  TODO: "bg-warm-200 text-jetBlack-600",
  OPEN: "bg-warm-200 text-jetBlack-600",
  IN_PROGRESS: "bg-blue-100 text-blue-800",
  DONE: "bg-success/10 text-success",
  PENDING: "bg-gold-100 text-gold-800",
  HIGH: "bg-destructive/10 text-destructive",
  MEDIUM: "bg-amber-100 text-amber-800",
  LOW: "bg-success/10 text-success",
  URGENT: "bg-destructive/10 text-destructive",
};

export const INVENTORY_CATEGORIES = [
  "CHAIRS", "TABLES", "STAGE", "LIGHTS", "GENERATOR", "SOUND_SYSTEM", "DECORATION",
] as const;

export const STAFF_ROLES = [
  "MANAGER", "COORDINATOR", "CHEF", "SERVER", "SECURITY", "CLEANER", "OTHER",
] as const;

export const TASK_PRIORITIES = ["HIGH", "MEDIUM", "LOW", "URGENT"] as const;

export const TASK_STATUSES = ["OPEN", "IN_PROGRESS", "COMPLETED", "CANCELLED"] as const;

export const VENDOR_SERVICE_TYPES = [
  "CATERER", "DECORATOR", "DJ", "PHOTOGRAPHER", "VIDEOGRAPHER", "SECURITY",
  "CLEANING", "OTHER",
] as const;

export const NOTIFICATION_TYPES = [
  "INFO", "SUCCESS", "WARNING", "ERROR",
] as const;
