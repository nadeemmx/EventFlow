import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:eventflow_app/features/venues/domain/repositories/venue_repository.dart';
import 'package:eventflow_app/features/venues/data/models/venue_model.dart';
import 'package:dio/dio.dart';

abstract class VenueEvent extends Equatable {
  const VenueEvent();
  @override
  List<Object?> get props => [];
}

class LoadVenues extends VenueEvent {
  final int page;
  final bool refresh;
  const LoadVenues({this.page = 1, this.refresh = false});
  @override
  List<Object?> get props => [page, refresh];
}

class LoadVenueDetail extends VenueEvent {
  final int id;
  const LoadVenueDetail({required this.id});
  @override
  List<Object?> get props => [id];
}

abstract class VenueState extends Equatable {
  const VenueState();
  @override
  List<Object?> get props => [];
}

class VenueInitial extends VenueState {}

class VenuesLoading extends VenueState {}

class VenuesLoaded extends VenueState {
  final List<VenueModel> venues;
  final bool hasMore;
  final int currentPage;
  const VenuesLoaded({required this.venues, required this.hasMore, required this.currentPage});
  @override
  List<Object?> get props => [venues, hasMore, currentPage];
}

class VenueDetailLoaded extends VenueState {
  final VenueModel venue;
  const VenueDetailLoaded({required this.venue});
  @override
  List<Object?> get props => [venue];
}

class VenueError extends VenueState {
  final String message;
  const VenueError({required this.message});
  @override
  List<Object?> get props => [message];
}

class VenueBloc extends Bloc<VenueEvent, VenueState> {
  final VenueRepository _repository;
  List<VenueModel> _allVenues = [];

  VenueBloc({required this._repository})
      : super(VenueInitial()) {
    on<LoadVenues>(_onLoad);
    on<LoadVenueDetail>(_onLoadDetail);
  }

  Future<void> _onLoad(LoadVenues event, Emitter<VenueState> emit) async {
    if (event.page == 1) emit(VenuesLoading());
    try {
      final response = await _repository.getVenues(page: event.page);
      final items = response.data ?? [];
      if (event.page == 1 || event.refresh) {
        _allVenues = items;
      } else {
        _allVenues.addAll(items);
      }
      emit(VenuesLoaded(
        venues: List.from(_allVenues),
        hasMore: response.pagination?.hasMore ?? false,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(VenueError(message: _extractMessage(e)));
    }
  }

  Future<void> _onLoadDetail(LoadVenueDetail event, Emitter<VenueState> emit) async {
    emit(VenuesLoading());
    try {
      final venue = await _repository.getVenue(event.id);
      emit(VenueDetailLoaded(venue: venue));
    } catch (e) {
      emit(VenueError(message: _extractMessage(e)));
    }
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
