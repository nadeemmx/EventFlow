
class DashboardModel {
  final double totalRevenue;
  final int totalBookings;
  final int activeBookings;
  final int totalCustomers;
  final int totalLeads;
  final double pendingPayments;
  final double occupancyRate;
  final List<RecentBooking> recentBookings;
  final List<UpcomingEvent> upcomingEvents;
  final List<MonthlyRevenue> monthlyRevenue;

  DashboardModel({
    required this.totalRevenue,
    required this.totalBookings,
    required this.activeBookings,
    required this.totalCustomers,
    required this.totalLeads,
    required this.pendingPayments,
    required this.occupancyRate,
    required this.recentBookings,
    required this.upcomingEvents,
    required this.monthlyRevenue,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      totalBookings: json['total_bookings'] as int? ?? 0,
      activeBookings: json['active_bookings'] as int? ?? 0,
      totalCustomers: json['total_customers'] as int? ?? 0,
      totalLeads: (json['active_leads'] as int?) ??
          json['total_leads'] as int? ??
          0,
      pendingPayments:
          (json['pending_payments'] as num?)?.toDouble() ?? 0,
      occupancyRate:
          (json['occupancy_rate'] as num?)?.toDouble() ?? 0,
      recentBookings: _parseRecentBookings(json),
      upcomingEvents: _parseUpcomingEvents(json),
      monthlyRevenue: _parseMonthlyRevenue(json),
    );
  }

  static List<RecentBooking> _parseRecentBookings(
      Map<String, dynamic> json) {
    final raw = json['recent_bookings'];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(RecentBooking.fromJson)
          .toList();
    }
    return [];
  }

  static List<UpcomingEvent> _parseUpcomingEvents(
      Map<String, dynamic> json) {
    final raw = json['upcoming_events'];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(UpcomingEvent.fromJson)
          .toList();
    }
    return [];
  }

  static List<MonthlyRevenue> _parseMonthlyRevenue(
      Map<String, dynamic> json) {
    final raw = json['monthly_revenue'];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(MonthlyRevenue.fromJson)
          .toList();
    }
    return [];
  }
}

class RecentBooking {
  final int id;
  final String bookingNumber;
  final String customerName;
  final String eventDate;
  final String status;
  final double totalAmount;

  RecentBooking({
    required this.id,
    required this.bookingNumber,
    required this.customerName,
    required this.eventDate,
    required this.status,
    required this.totalAmount,
  });

  factory RecentBooking.fromJson(Map<String, dynamic> json) {
    return RecentBooking(
      id: json['id'] as int? ?? 0,
      bookingNumber: json['booking_number'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      eventDate: json['event_date'] as String? ?? '',
      status: json['status'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class UpcomingEvent {
  final int id;
  final String bookingNumber;
  final String customerName;
  final String eventDate;
  final String? venueName;

  UpcomingEvent({
    required this.id,
    required this.bookingNumber,
    required this.customerName,
    required this.eventDate,
    this.venueName,
  });

  factory UpcomingEvent.fromJson(Map<String, dynamic> json) {
    return UpcomingEvent(
      id: json['id'] as int? ?? 0,
      bookingNumber: json['booking_number'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      eventDate: json['event_date'] as String? ?? '',
      venueName: json['venue_name'] as String?,
    );
  }
}

class MonthlyRevenue {
  final String month;
  final double amount;

  MonthlyRevenue({required this.month, required this.amount});

  factory MonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenue(
      month: json['month'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
