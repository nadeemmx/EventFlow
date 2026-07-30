import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:eventflow_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:eventflow_app/features/customers/data/models/customer_model.dart';
import 'package:dio/dio.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();
  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {
  final int page;
  final String? search;
  final bool refresh;
  const LoadCustomers({this.page = 1, this.search, this.refresh = false});
  @override
  List<Object?> get props => [page, search, refresh];
}

class LoadCustomerDetail extends CustomerEvent {
  final int id;
  const LoadCustomerDetail({required this.id});
}

class CreateCustomer extends CustomerEvent {
  final Map<String, dynamic> data;
  const CreateCustomer({required this.data});
}

class UpdateCustomer extends CustomerEvent {
  final int id;
  final Map<String, dynamic> data;
  const UpdateCustomer({required this.id, required this.data});
}

abstract class CustomerState extends Equatable {
  const CustomerState();
  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}
class CustomersLoading extends CustomerState {}

class CustomersLoaded extends CustomerState {
  final List<CustomerModel> customers;
  final bool hasMore;
  final int currentPage;
  const CustomersLoaded({required this.customers, required this.hasMore, required this.currentPage});
  @override
  List<Object?> get props => [customers, hasMore, currentPage];
}

class CustomerDetailLoaded extends CustomerState {
  final CustomerModel customer;
  const CustomerDetailLoaded({required this.customer});
}

class CustomerActionSuccess extends CustomerState {
  final String message;
  final CustomerModel? customer;
  const CustomerActionSuccess({this.message = 'Success', this.customer});
}

class CustomerError extends CustomerState {
  final String message;
  const CustomerError({required this.message});
}

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository _repository;
  List<CustomerModel> _allCustomers = [];

  CustomerBloc({required this._repository})
      : super(CustomerInitial()) {
    on<LoadCustomers>(_onLoad);
    on<LoadCustomerDetail>(_onLoadDetail);
    on<CreateCustomer>(_onCreate);
    on<UpdateCustomer>(_onUpdate);
  }

  Future<void> _onLoad(LoadCustomers event, Emitter<CustomerState> emit) async {
    if (event.page == 1) emit(CustomersLoading());
    try {
      final response = await _repository.getCustomers(page: event.page, search: event.search);
      final items = response.data ?? [];
      if (event.page == 1 || event.refresh) {
        _allCustomers = items;
      } else {
        _allCustomers.addAll(items);
      }
      emit(CustomersLoaded(
        customers: List.from(_allCustomers),
        hasMore: response.pagination?.hasMore ?? false,
        currentPage: event.page,
      ));
    } catch (e) {
      emit(CustomerError(message: _extractMessage(e)));
    }
  }

  Future<void> _onLoadDetail(LoadCustomerDetail event, Emitter<CustomerState> emit) async {
    emit(CustomersLoading());
    try {
      final c = await _repository.getCustomer(event.id);
      emit(CustomerDetailLoaded(customer: c));
    } catch (e) {
      emit(CustomerError(message: _extractMessage(e)));
    }
  }

  Future<void> _onCreate(CreateCustomer event, Emitter<CustomerState> emit) async {
    emit(CustomersLoading());
    try {
      final c = await _repository.createCustomer(event.data);
      emit(CustomerActionSuccess(message: 'Customer created', customer: c));
    } catch (e) {
      emit(CustomerError(message: _extractMessage(e)));
    }
  }

  Future<void> _onUpdate(UpdateCustomer event, Emitter<CustomerState> emit) async {
    emit(CustomersLoading());
    try {
      final c = await _repository.updateCustomer(event.id, event.data);
      emit(CustomerActionSuccess(message: 'Customer updated', customer: c));
    } catch (e) {
      emit(CustomerError(message: _extractMessage(e)));
    }
  }

  String _extractMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) return data['message'] as String? ?? 'Operation failed';
      return error.message ?? 'Operation failed';
    }
    return error.toString();
  }
}
