import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:eventflow_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:eventflow_app/features/dashboard/data/models/dashboard_model.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {}

class RefreshDashboard extends DashboardEvent {}

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardModel dashboard;
  const DashboardLoaded({required this.dashboard});
  @override
  List<Object?> get props => [dashboard];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError({required this.message});
  @override
  List<Object?> get props => [message];
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repository;

  DashboardBloc({required this._repository})
      : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
    on<RefreshDashboard>(_onRefresh);
  }

  Future<void> _onLoad(LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      final dashboard = await _repository.getSummary();
      emit(DashboardLoaded(dashboard: dashboard));
    } catch (e) {
      emit(DashboardError(message: _extractMessage(e)));
    }
  }

  Future<void> _onRefresh(RefreshDashboard event, Emitter<DashboardState> emit) async {
    try {
      final dashboard = await _repository.getSummary();
      emit(DashboardLoaded(dashboard: dashboard));
    } catch (e) {
      emit(DashboardError(message: _extractMessage(e)));
    }
  }

  String _extractMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? 'Failed to load dashboard';
      }
      return error.message ?? 'Failed to load dashboard';
    }
    return error.toString();
  }
}
