import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:eventflow_app/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:eventflow_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:eventflow_app/features/notifications/data/models/notification_model.dart';
import 'package:eventflow_app/core/api/api_response.dart';

class MockNotificationRepository extends Mock implements NotificationRepository {}

void main() {
  late NotificationBloc notificationBloc;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    notificationBloc = NotificationBloc(repository: mockRepository);
  });

  tearDown(() {
    notificationBloc.close();
  });

  final testNotification = NotificationModel(
    id: 1, title: 'Test', message: 'Message', channel: 'EMAIL',
    status: 'UNREAD', createdAt: '2024-01-15',
  );

  group('NotificationBloc', () {
    test('initial state is NotificationInitial', () {
      expect(notificationBloc.state, isA<NotificationInitial>());
    });

    blocTest<NotificationBloc, NotificationState>(
      'emits [NotificationLoading, NotificationListLoaded] when load succeeds',
      build: () {
        when(() => mockRepository.getNotifications(page: any(named: 'page')))
            .thenAnswer((_) async => ApiResponse<List<NotificationModel>>(
              success: true, message: 'OK', data: [testNotification]));
        return notificationBloc;
      },
      act: (bloc) => bloc.add(const LoadNotifications()),
      expect: () => [isA<NotificationLoading>(), isA<NotificationListLoaded>()],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [NotificationLoading, NotificationError] when load fails',
      build: () {
        when(() => mockRepository.getNotifications(page: any(named: 'page')))
            .thenThrow(Exception('Failed'));
        return notificationBloc;
      },
      act: (bloc) => bloc.add(const LoadNotifications()),
      expect: () => [isA<NotificationLoading>(), isA<NotificationError>()],
    );

    blocTest<NotificationBloc, NotificationState>(
      'marks notification as read',
      build: () {
        when(() => mockRepository.getNotifications(page: any(named: 'page')))
            .thenAnswer((_) async => ApiResponse<List<NotificationModel>>(
              success: true, message: 'OK', data: [testNotification]));
        when(() => mockRepository.markRead(any())).thenAnswer((_) async {});
        return notificationBloc;
      },
      act: (bloc) {
        bloc.add(const LoadNotifications());
        bloc.add(const MarkNotificationRead(id: 1));
      },
      expect: () => [
        isA<NotificationLoading>(),
        isA<NotificationListLoaded>(),
        isA<NotificationListLoaded>(),
      ],
    );
  });
}
