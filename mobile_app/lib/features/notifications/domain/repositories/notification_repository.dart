import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:eventflow_app/features/notifications/data/models/notification_model.dart';

class NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepository({required this._remoteDataSource});

  Future<ApiResponse<List<NotificationModel>>> getNotifications({int page = 1}) {
    return _remoteDataSource.getNotifications(page: page);
  }

  Future<void> markRead(int id) => _remoteDataSource.markRead(id);

  Future<void> registerFCMToken(String token) =>
      _remoteDataSource.registerFCMToken(token);

  Future<int?> getUnreadCount() =>
      _remoteDataSource.getUnreadCount();
}
