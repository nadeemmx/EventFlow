import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:eventflow_app/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:eventflow_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:eventflow_app/features/customers/data/models/customer_model.dart';
import 'package:eventflow_app/core/api/api_response.dart';

class MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late CustomerBloc customerBloc;
  late MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = MockCustomerRepository();
    customerBloc = CustomerBloc(repository: mockRepository);
  });

  tearDown(() {
    customerBloc.close();
  });

  final testCustomer = CustomerModel(
    id: 1, fullName: 'John Doe', mobile: '9876543210',
    email: 'john@test.com', address: 'Addr', createdAt: '2024-01-01',
  );

  group('CustomerBloc', () {
    test('initial state is CustomerInitial', () {
      expect(customerBloc.state, isA<CustomerInitial>());
    });

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomersLoading, CustomersLoaded] when load succeeds',
      build: () {
        when(() => mockRepository.getCustomers(page: any(named: 'page')))
            .thenAnswer((_) async => ApiResponse<List<CustomerModel>>(
              success: true, message: 'OK', data: [testCustomer]));
        return customerBloc;
      },
      act: (bloc) => bloc.add(const LoadCustomers()),
      expect: () => [isA<CustomersLoading>(), isA<CustomersLoaded>()],
    );

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomersLoading, CustomerError] when load fails',
      build: () {
        when(() => mockRepository.getCustomers(page: any(named: 'page')))
            .thenThrow(Exception('Failed'));
        return customerBloc;
      },
      act: (bloc) => bloc.add(const LoadCustomers()),
      expect: () => [isA<CustomersLoading>(), isA<CustomerError>()],
    );

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomersLoading, CustomerDetailLoaded] when detail succeeds',
      build: () {
        when(() => mockRepository.getCustomer(any())).thenAnswer((_) async => testCustomer);
        return customerBloc;
      },
      act: (bloc) => bloc.add(const LoadCustomerDetail(id: 1)),
      expect: () => [isA<CustomersLoading>(), isA<CustomerDetailLoaded>()],
    );

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomersLoading, CustomerActionSuccess] when create succeeds',
      build: () {
        when(() => mockRepository.createCustomer(any())).thenAnswer((_) async => testCustomer);
        return customerBloc;
      },
      act: (bloc) => bloc.add(const CreateCustomer(data: {})),
      expect: () => [isA<CustomersLoading>(), isA<CustomerActionSuccess>()],
    );

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomersLoading, CustomerActionSuccess] when update succeeds',
      build: () {
        when(() => mockRepository.updateCustomer(any(), any())).thenAnswer((_) async => testCustomer);
        return customerBloc;
      },
      act: (bloc) => bloc.add(const UpdateCustomer(id: 1, data: {})),
      expect: () => [isA<CustomersLoading>(), isA<CustomerActionSuccess>()],
    );
  });
}
