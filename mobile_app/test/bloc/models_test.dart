import 'package:flutter_test/flutter_test.dart';
import 'package:eventflow_app/features/authentication/data/models/user_model.dart';
import 'package:eventflow_app/features/authentication/data/models/login_response_model.dart';
import 'package:eventflow_app/features/bookings/data/models/booking_model.dart';
import 'package:eventflow_app/features/customers/data/models/customer_model.dart';
import 'package:eventflow_app/features/leads/data/models/lead_model.dart';
import 'package:eventflow_app/features/venues/data/models/venue_model.dart';
import 'package:eventflow_app/features/payments/data/models/payment_model.dart';
import 'package:eventflow_app/features/invoices/data/models/invoice_model.dart';
import 'package:eventflow_app/features/notifications/data/models/notification_model.dart';
import 'package:eventflow_app/features/dashboard/data/models/dashboard_model.dart';
import 'package:eventflow_app/core/api/api_response.dart';

void main() {
  group('UserModel', () {
    test('fromJson creates model correctly', () {
      final json = {
        'id': 1, 'full_name': 'Test', 'email': 'test@test.com',
        'mobile': '9876543210', 'role': 'OWNER', 'tenant_id': 1,
      };
      final model = UserModel.fromJson(json);
      expect(model.id, 1);
      expect(model.fullName, 'Test');
      expect(model.email, 'test@test.com');
      expect(model.mobile, '9876543210');
      expect(model.role, 'OWNER');
      expect(model.tenantId, 1);
    });

    test('toJson returns map', () {
      final model = UserModel(id: 1, fullName: 'Test', email: 'test@test.com', role: 'OWNER');
      final json = model.toJson();
      expect(json['full_name'], 'Test');
    });
  });

  group('LoginResponseModel', () {
    test('fromJson creates model correctly', () {
      final json = {
        'access_token': 'abc', 'refresh_token': 'def',
        'user': {'id': 1, 'full_name': 'Test', 'email': 'test@test.com', 'role': 'OWNER'},
      };
      final model = LoginResponseModel.fromJson(json);
      expect(model.accessToken, 'abc');
      expect(model.refreshToken, 'def');
      expect(model.user.fullName, 'Test');
    });
  });

  group('BookingModel', () {
    test('fromJson creates model correctly', () {
      final json = {
        'id': 1, 'booking_number': 'BK-001', 'venue': 1, 'venue_name': 'Hall',
        'customer': 1, 'customer_name': 'John', 'package': 1,
        'event_type': 'WEDDING', 'event_date': '2024-03-15', 'guest_count': 200,
        'total_amount': 50000, 'advance_amount': 10000, 'status': 'CONFIRMED',
        'remarks': 'Test', 'created_at': '2024-01-01',
      };
      final model = BookingModel.fromJson(json);
      expect(model.id, 1);
      expect(model.bookingNumber, 'BK-001');
      expect(model.status, 'CONFIRMED');
    });
  });

  group('CustomerModel', () {
    test('fromJson creates model correctly', () {
      final json = {
        'id': 1, 'full_name': 'John', 'mobile': '9876543210',
        'email': 'john@test.com', 'address': 'Addr', 'remarks': 'VIP',
        'created_at': '2024-01-01',
      };
      final model = CustomerModel.fromJson(json);
      expect(model.fullName, 'John');
      expect(model.mobile, '9876543210');
    });
  });

  group('LeadModel', () {
    test('fromJson creates model correctly', () {
      final json = {
        'id': 1, 'customer': 1, 'customer_name': 'John', 'lead_source': 'WEBSITE',
        'event_type': 'WEDDING', 'expected_event_date': '2024-06-01',
        'expected_guest_count': 200, 'lead_status': 'NEW', 'assigned_to': 1,
        'created_at': '2024-01-01',
      };
      final model = LeadModel.fromJson(json);
      expect(model.leadStatus, 'NEW');
      expect(model.customerName, 'John');
    });
  });

  group('VenueModel', () {
    test('fromJson creates model correctly', () {
      final json = {
        'id': 1, 'name': 'Grand Hall', 'venue_type': 'HALL', 'capacity': 500,
        'description': 'Test', 'address': 'Addr', 'latitude': 12.34, 'longitude': 56.78,
        'weekday_price': 50000, 'weekend_price': 75000, 'peak_price': 100000,
        'status': 'ACTIVE', 'created_at': '2024-01-01',
      };
      final model = VenueModel.fromJson(json);
      expect(model.name, 'Grand Hall');
      expect(model.capacity, 500);
    });
  });

  group('PaymentModel', () {
    test('fromJson creates model correctly', () {
      final json = {
        'id': 1, 'booking': 1, 'booking_number': 'BK-001', 'amount': 50000,
        'payment_method': 'CASH', 'payment_type': 'ADVANCE',
        'transaction_reference': 'TXN001', 'payment_date': '2024-01-15',
        'notes': 'Test', 'created_at': '2024-01-15',
      };
      final model = PaymentModel.fromJson(json);
      expect(model.amount, 50000);
      expect(model.paymentMethod, 'CASH');
    });
  });

  group('InvoiceModel', () {
    test('fromJson creates model correctly', () {
      final json = {
        'id': 1, 'booking': 1, 'invoice_number': 'INV-001',
        'invoice_date': '2024-01-15', 'subtotal': 42000, 'tax_amount': 8000,
        'total_amount': 50000, 'pdf_file': 'https://example.com/inv.pdf',
        'created_at': '2024-01-15',
      };
      final model = InvoiceModel.fromJson(json);
      expect(model.invoiceNumber, 'INV-001');
      expect(model.totalAmount, 50000);
    });
  });

  group('NotificationModel', () {
    test('fromJson creates model correctly', () {
      final json = {
        'id': 1, 'title': 'Test', 'message': 'Message', 'channel': 'EMAIL',
        'status': 'UNREAD', 'created_at': '2024-01-15',
      };
      final model = NotificationModel.fromJson(json);
      expect(model.title, 'Test');
      expect(model.status, 'UNREAD');
    });
  });

  group('DashboardModel', () {
    test('fromJson creates model correctly', () {
      final json = {
        'total_revenue': 100000, 'total_bookings': 50, 'active_bookings': 20,
        'total_customers': 100, 'total_leads': 30, 'pending_payments': 15000,
        'occupancy_rate': 75, 'recent_bookings': [], 'upcoming_events': [],
        'monthly_revenue': [{'month': 'Jan', 'amount': 20000}],
      };
      final model = DashboardModel.fromJson(json);
      expect(model.totalRevenue, 100000);
      expect(model.totalBookings, 50);
    });

    test('handles backend response with monthly_revenue as double', () {
      final json = {
        'today_events': 0,
        'upcoming_bookings': 0,
        'pending_payments': 0,
        'active_leads': 5,
        'monthly_revenue': 0.0,
      };
      final model = DashboardModel.fromJson(json);
      expect(model.monthlyRevenue, isEmpty);
      expect(model.totalLeads, 5);
      expect(model.pendingPayments, 0.0);
      expect(model.recentBookings, isEmpty);
      expect(model.upcomingEvents, isEmpty);
    });

    test('falls back to active_leads when total_leads missing', () {
      final json = {
        'active_leads': 12,
        'pending_payments': 5000,
        'monthly_revenue': 1000.0,
      };
      final model = DashboardModel.fromJson(json);
      expect(model.totalLeads, 12);
    });

    test('sub-models parse correctly', () {
      final recent = RecentBooking.fromJson({
        'id': 1, 'booking_number': 'BK-001', 'customer_name': 'John',
        'event_date': '2024-01-15', 'status': 'CONFIRMED', 'total_amount': 50000,
      });
      expect(recent.customerName, 'John');

      final upcoming = UpcomingEvent.fromJson({
        'id': 1, 'booking_number': 'BK-001', 'customer_name': 'Jane',
        'event_date': '2024-02-01', 'venue_name': 'Hall',
      });
      expect(upcoming.venueName, 'Hall');

      final monthly = MonthlyRevenue.fromJson({'month': 'Jan', 'amount': 20000});
      expect(monthly.amount, 20000);
    });
  });

  group('ApiResponse', () {
    test('fromJson creates response correctly', () {
      final json = {'success': true, 'message': 'OK', 'data': {'id': 1}};
      final response = ApiResponse.fromJson(json, (d) => d);
      expect(response.success, true);
      expect(response.message, 'OK');
    });

    test('fromJsonList creates list response correctly', () {
      final json = {
        'success': true, 'message': 'OK',
        'data': [{'id': 1}, {'id': 2}],
      };
      final response = ApiResponse.fromJsonList<int>(json, (d) => d['id'] as int);
      expect(response.data, [1, 2]);
    });

    test('PaginationMeta hasMore works correctly', () {
      final meta = PaginationMeta.fromJson({'page': 1, 'page_size': 20, 'total_records': 50, 'total_pages': 3});
      expect(meta.hasMore, true);

      final metaLast = PaginationMeta.fromJson({'page': 3, 'page_size': 20, 'total_records': 50, 'total_pages': 3});
      expect(metaLast.hasMore, false);
    });
  });
}
