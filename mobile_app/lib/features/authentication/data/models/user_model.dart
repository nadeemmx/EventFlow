class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String? mobile;
  final String role;
  final int? tenantId;
  final bool? isActive;
  final String? lastLogin;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.mobile,
    required this.role,
    this.tenantId,
    this.isActive,
    this.lastLogin,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      mobile: json['mobile'] as String?,
      role: json['role'] as String? ?? 'STAFF',
      tenantId: json['tenant_id'] as int?,
      isActive: json['is_active'] as bool?,
      lastLogin: json['last_login'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'mobile': mobile,
      'role': role,
      'tenant_id': tenantId,
      'is_active': isActive,
      'last_login': lastLogin,
      'created_at': createdAt,
    };
  }
}
