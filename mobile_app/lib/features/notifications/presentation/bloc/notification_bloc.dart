import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:eventflow_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:eventflow_app/features/notifications/data/models/notification_model.dart';
import 'package:dio/dio.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final int page;
  final bool refresh;
  const LoadNotifications({this.page = 1, this.refresh = false});
  @override
  List<Object?> get props => [page, refresh];
}

class MarkNotificationRead extends NotificationEvent {
  final int id;
  const MarkNotificationRead({required this.id});
  @override
  List<Object?> get props => [id];
}

class RegisterFCMToken extends NotificationEvent {
  final String token;
  const RegisterFCMToken({required this.token});
  @override
  List<Object?> get props => [token];
}

class LoadUnreadCount extends NotificationEvent {}

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationListLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final bool hasMore;
  final int currentPage;
  final int unreadCount;
  const NotificationListLoaded({
    required this.notifications,
    required this.hasMore,
    required this.currentPage,
    this.unreadCount = 0,
  });
  @override
  List<Object?> get props => [notifications, hasMore, currentPage, unreadCount];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError({required this.message});
  @override
  List<Object?> get props => [message];
}

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  List<NotificationModel> _allNotifications = [];

  NotificationBloc({required this._repository})
      : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoad);
    on<MarkNotificationRead>(_onMarkRead);
    on<RegisterFCMToken>(_onRegisterToken);
    on<LoadUnreadCount>(_onLoadUnreadCount);
  }

  Future<void> _onLoad(LoadNotifications event, Emitter<NotificationState> emit) async {
    if (event.page == 1) emit(NotificationLoading());
    try {
      final response = await _repository.getNotifications(page: event.page);
      final items = response.data ?? [];
      if (event.page == 1 || event.refresh) {
        _allNotifications = items;
      } else {
        _allNotifications.addAll(items);
      }
      emit(NotificationListLoaded(
        notifications: List.from(_allNotifications),
        hasMore: response.pagination?.hasMore ?? false,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(NotificationError(message: _extractMessage(e)));
    }
  }

  Future<void> _onMarkRead(MarkNotificationRead event, Emitter<NotificationState> emit) async {
    try {
      await _repository.markRead(event.id);
      final index = _allNotifications.indexWhere((n) => n.id == event.id);
      if (index != -1) {
        final old = _allNotifications[index];
        _allNotifications[index] = NotificationModel(
          id: old.id,
          title: old.title,
          message: old.message,
          channel: old.channel,
          status: 'READ',
          createdAt: old.createdAt,
        );
        final currentState = state;
        if (currentState is NotificationListLoaded) {
          emit(NotificationListLoaded(
            notifications: List.from(_allNotifications),
            hasMore: currentState.hasMore,
            currentPage: currentState.currentPage,
          ));
        }
      }
    } catch (e) {
      emit(NotificationError(message: _extractMessage(e)));
    }
  }

  Future<void> _onRegisterToken(RegisterFCMToken event, Emitter<NotificationState> emit) async {
    try {
      await _repository.registerFCMToken(event.token);
    } catch (_) {}
  }

  Future<void> _onLoadUnreadCount(LoadUnreadCount event, Emitter<NotificationState> emit) async {
    try {
      final count = await _repository.getUnreadCount();
      if (count != null && state is NotificationListLoaded) {
        final current = state as NotificationListLoaded;
        emit(NotificationListLoaded(
          notifications: current.notifications,
          hasMore: current.hasMore,
          currentPage: current.currentPage,
          unreadCount: count,
        ));
      }
    } catch (_) {}
  }

  String _extractMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? 'Operation failed';
      }
      return error.message ?? 'Operation failed';
    }
    return error.toString();
  }
}
