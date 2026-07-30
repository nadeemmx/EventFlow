import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/features/bookings/data/models/booking_model.dart';
import 'package:eventflow_app/features/customers/data/models/customer_model.dart';
import 'package:eventflow_app/features/leads/data/models/lead_model.dart';
import 'package:eventflow_app/features/payments/data/models/payment_model.dart';
import 'package:eventflow_app/features/invoices/data/models/invoice_model.dart';
import 'package:eventflow_app/features/notifications/data/models/notification_model.dart';
import 'package:eventflow_app/features/dashboard/data/models/dashboard_model.dart';

class MockDataFactory {
  static BookingModel createBooking() {
    return BookingModel(
      id: 1, bookingNumber: 'BK-001', venue: 1, venueName: 'Grand Hall',
      customer: 1, customerName: 'John Doe', package: null, eventType: 'WEDDING',
      eventDate: '2024-03-15', guestCount: 200, totalAmount: 50000.0,
      advanceAmount: 10000.0, status: 'CONFIRMED', remarks: 'Test', createdAt: '2024-01-01',
    );
  }

  static CustomerModel createCustomer() {
    return CustomerModel(
      id: 1, fullName: 'John Doe', mobile: '9876543210',
      email: 'john@example.com', address: 'Test Address',
      remarks: 'VIP', createdAt: '2024-01-01',
    );
  }

  static LeadModel createLead() {
    return LeadModel(
      id: 1, customer: 1, customerName: 'John Doe', leadSource: 'WEBSITE',
      eventType: 'WEDDING', expectedEventDate: '2024-06-01',
      expectedGuestCount: 200, leadStatus: 'NEW', assignedTo: 1,
      createdAt: '2024-01-01',
    );
  }

  static PaymentModel createPayment() {
    return PaymentModel(
      id: 1, booking: 1, bookingNumber: 'BK-001', amount: 50000.0,
      paymentMethod: 'CASH', paymentType: 'ADVANCE', transactionReference: 'TXN001',
      paymentDate: '2024-01-15', notes: 'Advance payment', createdAt: '2024-01-15',
    );
  }

  static InvoiceModel createInvoice() {
    return InvoiceModel(
      id: 1, booking: 1, invoiceNumber: 'INV-001', invoiceDate: '2024-01-15',
      subtotal: 42000.0, taxAmount: 8000.0, totalAmount: 50000.0,
      pdfFile: 'https://example.com/invoice.pdf', createdAt: '2024-01-15',
    );
  }

  static NotificationModel createNotification() {
    return NotificationModel(
      id: 1, title: 'Test Notification', message: 'This is a test',
      channel: 'EMAIL', status: 'UNREAD', createdAt: '2024-01-15',
    );
  }

  static DashboardModel createDashboard() {
    return DashboardModel(
      totalRevenue: 100000.0, totalBookings: 50, activeBookings: 20,
      totalCustomers: 100, totalLeads: 30, pendingPayments: 15000.0,
      occupancyRate: 75.0, recentBookings: [], upcomingEvents: [], monthlyRevenue: [],
    );
  }

  static ApiResponse<List<T>> createApiListResponse<T>(List<T> items) {
    return ApiResponse<List<T>>(
      success: true,
      message: 'Success',
      data: items,
    );
  }
}
