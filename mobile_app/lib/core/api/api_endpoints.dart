class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://eventflow.baseify.in/api/v1/',
  );

  // Auth
  static const String login = 'auth/login/';
  static const String refresh = 'auth/refresh/';
  static const String logout = 'auth/logout/';
  static const String forgotPassword = 'auth/forgot-password/';
  static const String resetPassword = 'auth/reset-password/';
  static const String changePassword = 'auth/change-password/';

  // Profile
  static const String profile = 'profile/';

  // Dashboard
  static const String dashboardSummary = 'dashboard/summary/';

  // Bookings
  static const String bookings = 'bookings/';
  static String bookingDetail(int id) => 'bookings/$id/';
  static String bookingConfirm(int id) => 'bookings/$id/confirm/';
  static String bookingCancel(int id) => 'bookings/$id/cancel/';
  static String bookingTimeline(int id) => 'bookings/$id/timeline/';
  static String bookingMarkInProgress(int id) =>
      'bookings/$id/mark_in_progress/';
  static String bookingMarkCompleted(int id) => 'bookings/$id/mark_completed/';
  static String bookingCalendar = 'bookings/calendar/';
  static String bookingOutstanding(int id) => 'bookings/$id/outstanding/';

  // Customers
  static const String customers = 'customers/';
  static String customerDetail(int id) => 'customers/$id/';
  static const String customerMerge = 'customers/merge/';

  // Leads
  static const String leads = 'leads/';
  static String leadDetail(int id) => 'leads/$id/';
  static String leadConvert(int id) => 'leads/$id/convert/';
  static String leadFollowups(int id) => 'leads/$id/followups/';
  static String leadAddFollowup(int id) => 'leads/$id/add_followup/';

  // Venues
  static const String venues = 'venues/';
  static String venueDetail(int id) => 'venues/$id/';
  static String venueImages(int id) => 'venues/$id/images/';

  // Payments
  static const String payments = 'payments/';
  static String paymentDetail(int id) => 'payments/$id/';
  static String paymentRefund(int id) => 'payments/$id/refund/';
  static String paymentReceipt(int id) => 'payments/$id/receipt/';
  static String paymentReceiptPdf(int id) => 'payments/$id/receipt_pdf/';
  static const String paymentSummary = 'payments/summary/';
  static const String paymentCreateOrder = 'payments/create_order/';
  static const String paymentVerify = 'payments/verify/';

  // Invoices
  static const String invoices = 'invoices/';
  static String invoiceDetail(int id) => 'invoices/$id/';
  static const String invoiceGenerate = 'invoices/generate/';
  static String invoicePdf(int id) => 'invoices/$id/pdf/';
  static String invoiceEmail(int id) => 'invoices/$id/email/';

  // Packages
  static const String packages = 'packages/';
  static String packageDetail(int id) => 'packages/$id/';

  // Notifications
  static const String notifications = 'notifications/';
  static String notificationDetail(int id) => 'notifications/$id/';
  static String notificationMarkRead(int id) => 'notifications/$id/mark_read/';
  static const String notificationRegisterDevice =
      'notifications/register_device/';

  // Settings
  static const String settingsPaymentGateway = 'settings/payment_gateway/';
  static const String settingsWhatsapp = 'settings/whatsapp/';
  static const String settingsEmail = 'settings/email/';
  static const String settingsInvoice = 'settings/invoice/';
  static const String settingsBooking = 'settings/booking/';
  static const String settingsNotifications = 'settings/notifications/';
  static const String settingsBranding = 'settings/branding/';
  static const String settingsOrganization = 'settings/organization/';
  static const String settingsRoles = 'settings/roles/';
  static const String settingsSubscription = 'settings/subscription/';

  // Reports
  static const String reportsRevenue = 'reports/revenue/';
  static const String reportsBookings = 'reports/bookings/';
  static const String reportsPayments = 'reports/payments/';
  static const String reportsOccupancy = 'reports/occupancy/';
  static const String reportsLeads = 'reports/leads/';
  static const String reportsVendors = 'reports/vendors/';
  static const String reportsInventory = 'reports/inventory/';
  static const String reportsOutstanding = 'reports/outstanding/';
  static const String reportsMonthlyGrowth = 'reports/monthly_growth/';
  static const String reportsExport = 'reports/export/';

  // Tenants
  static const String tenants = 'tenants/';
  static String tenantDetail(int id) => 'tenants/$id/';
  static const String tenantSettings = 'tenants/settings/';

  // Users
  static const String users = 'users/';
  static String userDetail(int id) => 'users/$id/';
  static String userActivate(int id) => 'users/$id/activate/';
  static String userDeactivate(int id) => 'users/$id/deactivate/';

  // Subscriptions
  static const String subscriptionPlans = 'subscriptions/plans/';
  static const String subscriptionCurrent = 'subscriptions/current/';
  static const String subscriptionHistory = 'subscriptions/history/';
  static const String subscriptionRenew = 'subscriptions/renew/';

  // Contracts
  static const String contracts = 'contracts/';
  static String contractDetail(int id) => 'contracts/$id/';
  static const String contractGenerate = 'contracts/generate/';
  static String contractPdf(int id) => 'contracts/$id/pdf/';
  static String contractSign(int id) => 'contracts/$id/sign/';
  static String contractCancel(int id) => 'contracts/$id/cancel/';

  // Quotations
  static const String quotations = 'quotations/';
  static String quotationDetail(int id) => 'quotations/$id/';
  static String quotationSend(int id) => 'quotations/$id/send/';
  static String quotationAccept(int id) => 'quotations/$id/accept/';
  static String quotationReject(int id) => 'quotations/$id/reject/';

  // Staff
  static const String staff = 'staff/';
  static String staffDetail(int id) => 'staff/$id/';

  // Tasks
  static const String tasks = 'tasks/';
  static String taskDetail(int id) => 'tasks/$id/';
  static String taskStatus(int id) => 'tasks/$id/status/';

  // Expenses
  static const String expenses = 'expenses/';
  static String expenseDetail(int id) => 'expenses/$id/';

  // Inventory
  static const String inventory = 'inventory/';
  static String inventoryDetail(int id) => 'inventory/$id/';
  static const String inventoryAllocate = 'inventory/allocate/';
  static const String inventoryRelease = 'inventory/release/';

  // Vendors
  static const String vendors = 'vendors/';
  static String vendorDetail(int id) => 'vendors/$id/';
  static const String vendorAssign = 'vendors/assign/';

  // Quotations
  static const String quotationsList = 'quotations/';

  // Audit Logs
  static const String auditLogs = 'audit-logs/';
  static String auditLogDetail(int id) => 'audit-logs/$id/';
}
