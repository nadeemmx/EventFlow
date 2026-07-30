import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:eventflow_app/features/bookings/domain/repositories/booking_repository.dart';
import 'package:eventflow_app/features/bookings/data/models/booking_model.dart';
import 'package:dio/dio.dart';

// Events
abstract class BookingEvent extends Equatable {
  const BookingEvent();
  @override
  List<Object?> get props => [];
}

class LoadBookings extends BookingEvent {
  final int page;
  final String? search;
  final String? status;
  final int? venue;
  final bool refresh;
  const LoadBookings({this.page = 1, this.search, this.status, this.venue, this.refresh = false});
  @override
  List<Object?> get props => [page, search, status, venue, refresh];
}

class LoadBookingDetail extends BookingEvent {
  final int id;
  const LoadBookingDetail({required this.id});
  @override
  List<Object?> get props => [id];
}

class CreateBooking extends BookingEvent {
  final Map<String, dynamic> data;
  const CreateBooking({required this.data});
  @override
  List<Object?> get props => [data];
}

class UpdateBooking extends BookingEvent {
  final int id;
  final Map<String, dynamic> data;
  const UpdateBooking({required this.id, required this.data});
  @override
  List<Object?> get props => [id, data];
}

class ConfirmBooking extends BookingEvent {
  final int id;
  const ConfirmBooking({required this.id});
}

class CancelBooking extends BookingEvent {
  final int id;
  final String? remarks;
  const CancelBooking({required this.id, this.remarks});
}

class MarkBookingInProgress extends BookingEvent {
  final int id;
  const MarkBookingInProgress({required this.id});
}

class MarkBookingCompleted extends BookingEvent {
  final int id;
  const MarkBookingCompleted({required this.id});
}

// States
abstract class BookingState extends Equatable {
  const BookingState();
  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingsLoading extends BookingState {}

class BookingsLoaded extends BookingState {
  final List<BookingModel> bookings;
  final bool hasMore;
  final int currentPage;
  const BookingsLoaded({required this.bookings, required this.hasMore, required this.currentPage});
  @override
  List<Object?> get props => [bookings, hasMore, currentPage];
}

class BookingDetailLoaded extends BookingState {
  final BookingModel booking;
  const BookingDetailLoaded({required this.booking});
  @override
  List<Object?> get props => [booking];
}

class BookingActionSuccess extends BookingState {
  final String message;
  final BookingModel? booking;
  const BookingActionSuccess({this.message = 'Success', this.booking});
  @override
  List<Object?> get props => [message, booking];
}

class BookingError extends BookingState {
  final String message;
  const BookingError({required this.message});
  @override
  List<Object?> get props => [message];
}

// BLoC
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _repository;
  List<BookingModel> _allBookings = [];

  BookingBloc({required this._repository})
      : super(BookingInitial()) {
    on<LoadBookings>(_onLoadBookings);
    on<LoadBookingDetail>(_onLoadDetail);
    on<CreateBooking>(_onCreate);
    on<UpdateBooking>(_onUpdate);
    on<ConfirmBooking>(_onConfirm);
    on<CancelBooking>(_onCancel);
    on<MarkBookingInProgress>(_onMarkInProgress);
    on<MarkBookingCompleted>(_onMarkCompleted);
  }

  Future<void> _onLoadBookings(LoadBookings event, Emitter<BookingState> emit) async {
    if (event.page == 1) {
      emit(BookingsLoading());
    }
    try {
      final response = await _repository.getBookings(
        page: event.page,
        search: event.search,
        status: event.status,
        venue: event.venue,
      );
      final items = response.data ?? [];
      if (event.page == 1 || event.refresh) {
        _allBookings = items;
      } else {
        _allBookings.addAll(items);
      }
      emit(BookingsLoaded(
        bookings: List.from(_allBookings),
        hasMore: response.pagination?.hasMore ?? false,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(BookingError(message: _extractMessage(e)));
    }
  }

  Future<void> _onLoadDetail(LoadBookingDetail event, Emitter<BookingState> emit) async {
    emit(BookingsLoading());
    try {
      final booking = await _repository.getBooking(event.id);
      emit(BookingDetailLoaded(booking: booking));
    } catch (e) {
      emit(BookingError(message: _extractMessage(e)));
    }
  }

  Future<void> _onCreate(CreateBooking event, Emitter<BookingState> emit) async {
    emit(BookingsLoading());
    try {
      final booking = await _repository.createBooking(event.data);
      emit(BookingActionSuccess(message: 'Booking created successfully', booking: booking));
    } catch (e) {
      emit(BookingError(message: _extractMessage(e)));
    }
  }

  Future<void> _onUpdate(UpdateBooking event, Emitter<BookingState> emit) async {
    emit(BookingsLoading());
    try {
      final booking = await _repository.updateBooking(event.id, event.data);
      emit(BookingActionSuccess(message: 'Booking updated successfully', booking: booking));
    } catch (e) {
      emit(BookingError(message: _extractMessage(e)));
    }
  }

  Future<void> _onConfirm(ConfirmBooking event, Emitter<BookingState> emit) async {
    try {
      final booking = await _repository.confirmBooking(event.id);
      emit(BookingActionSuccess(message: 'Booking confirmed', booking: booking));
    } catch (e) {
      emit(BookingError(message: _extractMessage(e)));
    }
  }

  Future<void> _onCancel(CancelBooking event, Emitter<BookingState> emit) async {
    try {
      final booking = await _repository.cancelBooking(event.id, remarks: event.remarks);
      emit(BookingActionSuccess(message: 'Booking cancelled', booking: booking));
    } catch (e) {
      emit(BookingError(message: _extractMessage(e)));
    }
  }

  Future<void> _onMarkInProgress(MarkBookingInProgress event, Emitter<BookingState> emit) async {
    try {
      final booking = await _repository.markInProgress(event.id);
      emit(BookingActionSuccess(message: 'Booking marked in progress', booking: booking));
    } catch (e) {
      emit(BookingError(message: _extractMessage(e)));
    }
  }

  Future<void> _onMarkCompleted(MarkBookingCompleted event, Emitter<BookingState> emit) async {
    try {
      final booking = await _repository.markCompleted(event.id);
      emit(BookingActionSuccess(message: 'Booking completed', booking: booking));
    } catch (e) {
      emit(BookingError(message: _extractMessage(e)));
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
