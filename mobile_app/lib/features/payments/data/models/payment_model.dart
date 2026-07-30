class PaymentModel {
  final int id;
  final int booking;
  final String bookingNumber;
  final double amount;
  final String paymentMethod;
  final String paymentType;
  final String? transactionReference;
  final String paymentDate;
  final String? notes;
  final String? createdAt;

  PaymentModel({
    required this.id,
    required this.booking,
    required this.bookingNumber,
    required this.amount,
    required this.paymentMethod,
    required this.paymentType,
    this.transactionReference,
    required this.paymentDate,
    this.notes,
    this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int? ?? 0,
      booking: json['booking'] as int? ?? 0,
      bookingNumber: json['booking_number'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['payment_method'] as String? ?? '',
      paymentType: json['payment_type'] as String? ?? '',
      transactionReference: json['transaction_reference'] as String?,
      paymentDate: json['payment_date'] as String? ?? '',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
