class LeadModel {
  final int id;
  final int customer;
  final String customerName;
  final String? leadSource;
  final String? eventType;
  final String? expectedEventDate;
  final int? expectedGuestCount;
  final String leadStatus;
  final int? assignedTo;
  final String? createdAt;

  LeadModel({
    required this.id,
    required this.customer,
    required this.customerName,
    this.leadSource,
    this.eventType,
    this.expectedEventDate,
    this.expectedGuestCount,
    required this.leadStatus,
    this.assignedTo,
    this.createdAt,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] as int? ?? 0,
      customer: json['customer'] as int? ?? 0,
      customerName: json['customer_name'] as String? ?? '',
      leadSource: json['lead_source'] as String?,
      eventType: json['event_type'] as String?,
      expectedEventDate: json['expected_event_date'] as String?,
      expectedGuestCount: json['expected_guest_count'] as int?,
      leadStatus: json['lead_status'] as String? ?? 'NEW',
      assignedTo: json['assigned_to'] as int?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer': customer,
      if (leadSource != null) 'lead_source': leadSource,
      if (eventType != null) 'event_type': eventType,
      if (expectedEventDate != null) 'expected_event_date': expectedEventDate,
      if (expectedGuestCount != null) 'expected_guest_count': expectedGuestCount,
      if (leadStatus != 'NEW') 'lead_status': leadStatus,
      if (assignedTo != null) 'assigned_to': assignedTo,
    };
  }
}
