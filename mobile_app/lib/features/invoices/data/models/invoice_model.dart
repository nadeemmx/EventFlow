class InvoiceModel {
  final int id;
  final int booking;
  final String invoiceNumber;
  final String invoiceDate;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String? pdfFile;
  final String? createdAt;

  InvoiceModel({
    required this.id,
    required this.booking,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    this.pdfFile,
    this.createdAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as int? ?? 0,
      booking: json['booking'] as int? ?? 0,
      invoiceNumber: json['invoice_number'] as String? ?? '',
      invoiceDate: json['invoice_date'] as String? ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      pdfFile: json['pdf_file'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
