import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:eventflow_app/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:eventflow_app/features/payments/domain/repositories/payment_repository.dart';
import 'package:eventflow_app/features/payments/data/models/payment_model.dart';
import 'package:eventflow_app/core/api/api_response.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {}

void main() {
  late PaymentBloc paymentBloc;
  late MockPaymentRepository mockRepository;

  setUp(() {
    mockRepository = MockPaymentRepository();
    paymentBloc = PaymentBloc(repository: mockRepository);
  });

  tearDown(() {
    paymentBloc.close();
  });

  final testPayment = PaymentModel(
    id: 1, booking: 1, bookingNumber: 'BK-001', amount: 50000,
    paymentMethod: 'CASH', paymentType: 'ADVANCE',
    paymentDate: '2024-01-15',
  );

  group('PaymentBloc', () {
    test('initial state is PaymentInitial', () {
      expect(paymentBloc.state, isA<PaymentInitial>());
    });

    blocTest<PaymentBloc, PaymentState>(
      'emits [PaymentLoading, PaymentListLoaded] when load succeeds',
      build: () {
        when(() => mockRepository.getPayments(page: any(named: 'page')))
            .thenAnswer((_) async => ApiResponse<List<PaymentModel>>(
              success: true, message: 'OK', data: [testPayment]));
        return paymentBloc;
      },
      act: (bloc) => bloc.add(const LoadPayments()),
      expect: () => [isA<PaymentLoading>(), isA<PaymentListLoaded>()],
    );

    blocTest<PaymentBloc, PaymentState>(
      'emits [PaymentLoading, PaymentError] when load fails',
      build: () {
        when(() => mockRepository.getPayments(page: any(named: 'page')))
            .thenThrow(Exception('Failed'));
        return paymentBloc;
      },
      act: (bloc) => bloc.add(const LoadPayments()),
      expect: () => [isA<PaymentLoading>(), isA<PaymentError>()],
    );

    blocTest<PaymentBloc, PaymentState>(
      'emits [PaymentLoading, PaymentOrderCreated] when create order succeeds',
      build: () {
        when(() => mockRepository.createOrder(bookingId: any(named: 'bookingId'), amount: any(named: 'amount')))
            .thenAnswer((_) async => {'id': 'order_123', 'amount': 50000});
        return paymentBloc;
      },
      act: (bloc) => bloc.add(const CreateRazorpayOrder(bookingId: 1, amount: 50000)),
      expect: () => [isA<PaymentLoading>(), isA<PaymentOrderCreated>()],
    );

    blocTest<PaymentBloc, PaymentState>(
      'emits [PaymentLoading, PaymentVerificationSuccess] when verify succeeds',
      build: () {
        when(() => mockRepository.verifyPayment(
          razorpayOrderId: any(named: 'razorpayOrderId'),
          razorpayPaymentId: any(named: 'razorpayPaymentId'),
          razorpaySignature: any(named: 'razorpaySignature'),
          bookingId: any(named: 'bookingId'),
        )).thenAnswer((_) async => {'status': 'captured'});
        return paymentBloc;
      },
      act: (bloc) => bloc.add(const VerifyRazorpayPayment(
        razorpayOrderId: 'order_123', razorpayPaymentId: 'pay_123',
        razorpaySignature: 'sig_123', bookingId: 1,
      )),
      expect: () => [isA<PaymentLoading>(), isA<PaymentVerificationSuccess>()],
    );
  });
}
