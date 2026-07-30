class BookingModel {
  final int id;
  final String bookingNumber;
  final int? venue;
  final String? venueName;
  final int customer;
  final String customerName;
  final int? package;
  final String eventType;
  final String eventDate;
  final int guestCount;
  final double totalAmount;
  final double advanceAmount;
  final String status;
  final String? remarks;
  final String? createdAt;

  BookingModel({
    required this.id,
    required this.bookingNumber,
    this.venue,
    this.venueName,
    required this.customer,
    required this.customerName,
    this.package,
    required this.eventType,
    required this.eventDate,
    required this.guestCount,
    required this.totalAmount,
    required this.advanceAmount,
    required this.status,
    this.remarks,
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as int? ?? 0,
      bookingNumber: json['booking_number'] as String? ?? '',
      venue: json['venue'] as int?,
      venueName: json['venue_name'] as String?,
      customer: json['customer'] as int? ?? 0,
      customerName: json['customer_name'] as String? ?? '',
      package: json['package'] as int?,
      eventType: json['event_type'] as String? ?? '',
      eventDate: json['event_date'] as String? ?? '',
      guestCount: json['guest_count'] as int? ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      advanceAmount: (json['advance_amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'DRAFT',
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      if (venue != null) 'venue': venue,
      'customer': customer,
      if (package != null) 'package': package,
      'event_type': eventType,
      'event_date': eventDate,
      'guest_count': guestCount,
      'total_amount': totalAmount,
      'advance_amount': advanceAmount,
      if (remarks != null) 'remarks': remarks,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (venue != null) 'venue': venue,
      'customer': customer,
      if (package != null) 'package': package,
      'event_type': eventType,
      'event_date': eventDate,
      'guest_count': guestCount,
      'total_amount': totalAmount,
      'advance_amount': advanceAmount,
      if (remarks != null) 'remarks': remarks,
    };
  }
}
