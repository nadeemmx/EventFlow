import 'package:eventflow_app/core/api/api_client.dart';
import 'package:eventflow_app/core/api/api_endpoints.dart';
import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/features/notifications/data/models/notification_model.dart';

class NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSource({required this._apiClient});

  Future<ApiResponse<List<NotificationModel>>> getNotifications({int page = 1}) async {
    final response = await _apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: {'page': page},
    );
    return ApiResponse.fromJsonList(
      response.data as Map<String, dynamic>,
      (data) => NotificationModel.fromJson(data),
    );
  }

  Future<void> markRead(int id) async {
    await _apiClient.post(ApiEndpoints.notificationMarkRead(id));
  }

  Future<void> registerFCMToken(String token) async {
    await _apiClient.post(
      ApiEndpoints.notificationRegisterDevice,
      data: {
        'fcm_token': token,
        'device_type': 'mobile',
      },
    );
  }

  Future<int?> getUnreadCount() async {
    final response = await _apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: {'page': 1, 'page_size': 1, 'status': 'UNREAD'},
    );
    final data = response.data as Map<String, dynamic>;
    return data['pagination'] != null
        ? (data['pagination'] as Map<String, dynamic>)['total_records'] as int?
        : null;
  }
}
