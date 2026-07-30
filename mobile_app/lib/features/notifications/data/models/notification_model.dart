class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String channel;
  final String status;
  final String? createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.channel,
    required this.status,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      status: json['status'] as String? ?? 'UNREAD',
      createdAt: json['created_at'] as String?,
    );
  }
}
