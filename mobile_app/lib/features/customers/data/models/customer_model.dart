class CustomerModel {
  final int id;
  final String fullName;
  final String mobile;
  final String? email;
  final String? address;
  final String? remarks;
  final String? createdAt;

  CustomerModel({
    required this.id,
    required this.fullName,
    required this.mobile,
    this.email,
    this.address,
    this.remarks,
    this.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int? ?? 0,
      fullName: json['full_name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      email: json['email'] as String?,
      address: json['address'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'mobile': mobile,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (remarks != null) 'remarks': remarks,
    };
  }
}
