import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:eventflow_app/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:eventflow_app/features/invoices/data/models/invoice_model.dart';
import 'package:dio/dio.dart';

abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();
  @override
  List<Object?> get props => [];
}

class LoadInvoices extends InvoiceEvent {
  final int page;
  final bool refresh;
  const LoadInvoices({this.page = 1, this.refresh = false});
  @override
  List<Object?> get props => [page, refresh];
}

class LoadInvoiceDetail extends InvoiceEvent {
  final int id;
  const LoadInvoiceDetail({required this.id});
  @override
  List<Object?> get props => [id];
}

abstract class InvoiceState extends Equatable {
  const InvoiceState();
  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {}

class InvoiceLoading extends InvoiceState {}

class InvoiceListLoaded extends InvoiceState {
  final List<InvoiceModel> invoices;
  final bool hasMore;
  final int currentPage;
  const InvoiceListLoaded({required this.invoices, required this.hasMore, required this.currentPage});
  @override
  List<Object?> get props => [invoices, hasMore, currentPage];
}

class InvoiceDetailLoaded extends InvoiceState {
  final InvoiceModel invoice;
  const InvoiceDetailLoaded({required this.invoice});
  @override
  List<Object?> get props => [invoice];
}

class InvoiceError extends InvoiceState {
  final String message;
  const InvoiceError({required this.message});
  @override
  List<Object?> get props => [message];
}

class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final InvoiceRepository _repository;
  List<InvoiceModel> _allInvoices = [];

  InvoiceBloc({required this._repository})
      : super(InvoiceInitial()) {
    on<LoadInvoices>(_onLoad);
    on<LoadInvoiceDetail>(_onLoadDetail);
  }

  Future<void> _onLoad(LoadInvoices event, Emitter<InvoiceState> emit) async {
    if (event.page == 1) emit(InvoiceLoading());
    try {
      final response = await _repository.getInvoices(page: event.page);
      final items = response.data ?? [];
      if (event.page == 1 || event.refresh) {
        _allInvoices = items;
      } else {
        _allInvoices.addAll(items);
      }
      emit(InvoiceListLoaded(
        invoices: List.from(_allInvoices),
        hasMore: response.pagination?.hasMore ?? false,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(InvoiceError(message: _extractMessage(e)));
    }
  }

  Future<void> _onLoadDetail(LoadInvoiceDetail event, Emitter<InvoiceState> emit) async {
    emit(InvoiceLoading());
    try {
      final invoice = await _repository.getInvoiceDetail(event.id);
      emit(InvoiceDetailLoaded(invoice: invoice));
    } catch (e) {
      emit(InvoiceError(message: _extractMessage(e)));
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
