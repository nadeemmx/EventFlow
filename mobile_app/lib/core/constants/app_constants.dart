class AppConstants {
  static const String appName = 'EventFlow';
  static const int pageSize = 20;

  // User Roles
  static const String roleSuperAdmin = 'SUPER_ADMIN';
  static const String roleOwner = 'OWNER';
  static const String roleManager = 'MANAGER';
  static const String roleAccountant = 'ACCOUNTANT';
  static const String roleStaff = 'STAFF';

  // Booking Status
  static const String bookingDraft = 'DRAFT';
  static const String bookingTentative = 'TENTATIVE';
  static const String bookingConfirmed = 'CONFIRMED';
  static const String bookingInProgress = 'IN_PROGRESS';
  static const String bookingCompleted = 'COMPLETED';
  static const String bookingCancelled = 'CANCELLED';

  // Lead Status
  static const String leadNew = 'NEW';
  static const String leadContacted = 'CONTACTED';
  static const String leadSiteVisit = 'SITE_VISIT';
  static const String leadNegotiation = 'NEGOTIATION';
  static const String leadQuotationSent = 'QUOTATION_SENT';
  static const String leadConverted = 'CONVERTED';
  static const String leadLost = 'LOST';

  // Payment Method
  static const String paymentCash = 'CASH';
  static const String paymentUpi = 'UPI';
  static const String paymentBankTransfer = 'BANK_TRANSFER';
  static const String paymentCheque = 'CHEQUE';
  static const String paymentCard = 'CARD';
  static const String paymentRazorpay = 'RAZORPAY';
}
