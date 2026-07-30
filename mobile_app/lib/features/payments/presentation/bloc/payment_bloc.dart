import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:eventflow_app/features/payments/domain/repositories/payment_repository.dart';
import 'package:eventflow_app/features/payments/data/models/payment_model.dart';
import 'package:dio/dio.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object?> get props => [];
}

class LoadPayments extends PaymentEvent {
  final int page;
  final bool refresh;
  const LoadPayments({this.page = 1, this.refresh = false});
  @override
  List<Object?> get props => [page, refresh];
}

class CreateRazorpayOrder extends PaymentEvent {
  final int bookingId;
  final double amount;
  const CreateRazorpayOrder({required this.bookingId, required this.amount});
  @override
  List<Object?> get props => [bookingId, amount];
}

class VerifyRazorpayPayment extends PaymentEvent {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;
  final int bookingId;
  const VerifyRazorpayPayment({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
    required this.bookingId,
  });
  @override
  List<Object?> get props => [razorpayOrderId, razorpayPaymentId, razorpaySignature, bookingId];
}

abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentListLoaded extends PaymentState {
  final List<PaymentModel> payments;
  final bool hasMore;
  final int currentPage;
  const PaymentListLoaded({required this.payments, required this.hasMore, required this.currentPage});
  @override
  List<Object?> get props => [payments, hasMore, currentPage];
}

class PaymentError extends PaymentState {
  final String message;
  const PaymentError({required this.message});
  @override
  List<Object?> get props => [message];
}

class PaymentOrderCreated extends PaymentState {
  final Map<String, dynamic> orderData;
  const PaymentOrderCreated({required this.orderData});
  @override
  List<Object?> get props => [orderData];
}

class PaymentVerificationSuccess extends PaymentState {
  final Map<String, dynamic> paymentData;
  const PaymentVerificationSuccess({required this.paymentData});
  @override
  List<Object?> get props => [paymentData];
}

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _repository;
  List<PaymentModel> _allPayments = [];

  PaymentBloc({required this._repository})
      : super(PaymentInitial()) {
    on<LoadPayments>(_onLoad);
    on<CreateRazorpayOrder>(_onCreateOrder);
    on<VerifyRazorpayPayment>(_onVerifyPayment);
  }

  Future<void> _onLoad(LoadPayments event, Emitter<PaymentState> emit) async {
    if (event.page == 1) emit(PaymentLoading());
    try {
      final response = await _repository.getPayments(page: event.page);
      final items = response.data ?? [];
      if (event.page == 1 || event.refresh) {
        _allPayments = items;
      } else {
        _allPayments.addAll(items);
      }
      emit(PaymentListLoaded(
        payments: List.from(_allPayments),
        hasMore: response.pagination?.hasMore ?? false,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(PaymentError(message: _extractMessage(e)));
    }
  }

  Future<void> _onCreateOrder(CreateRazorpayOrder event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      final orderData = await _repository.createOrder(
        bookingId: event.bookingId,
        amount: event.amount,
      );
      emit(PaymentOrderCreated(orderData: orderData));
    } catch (e) {
      emit(PaymentError(message: _extractMessage(e)));
    }
  }

  Future<void> _onVerifyPayment(VerifyRazorpayPayment event, Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      final paymentData = await _repository.verifyPayment(
        razorpayOrderId: event.razorpayOrderId,
        razorpayPaymentId: event.razorpayPaymentId,
        razorpaySignature: event.razorpaySignature,
        bookingId: event.bookingId,
      );
      emit(PaymentVerificationSuccess(paymentData: paymentData));
    } catch (e) {
      emit(PaymentError(message: _extractMessage(e)));
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
