import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:eventflow_app/features/invoices/presentation/bloc/invoice_bloc.dart';
import 'package:eventflow_app/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:eventflow_app/features/invoices/data/models/invoice_model.dart';
import 'package:eventflow_app/core/api/api_response.dart';

class MockInvoiceRepository extends Mock implements InvoiceRepository {}

void main() {
  late InvoiceBloc invoiceBloc;
  late MockInvoiceRepository mockRepository;

  setUp(() {
    mockRepository = MockInvoiceRepository();
    invoiceBloc = InvoiceBloc(repository: mockRepository);
  });

  tearDown(() {
    invoiceBloc.close();
  });

  final testInvoice = InvoiceModel(
    id: 1, booking: 1, invoiceNumber: 'INV-001', invoiceDate: '2024-01-15',
    subtotal: 42000, taxAmount: 8000, totalAmount: 50000,
    pdfFile: 'https://example.com/inv.pdf', createdAt: '2024-01-15',
  );

  group('InvoiceBloc', () {
    test('initial state is InvoiceInitial', () {
      expect(invoiceBloc.state, isA<InvoiceInitial>());
    });

    blocTest<InvoiceBloc, InvoiceState>(
      'emits [InvoiceLoading, InvoiceListLoaded] when load succeeds',
      build: () {
        when(() => mockRepository.getInvoices(page: any(named: 'page')))
            .thenAnswer((_) async => ApiResponse<List<InvoiceModel>>(
              success: true, message: 'OK', data: [testInvoice]));
        return invoiceBloc;
      },
      act: (bloc) => bloc.add(const LoadInvoices()),
      expect: () => [isA<InvoiceLoading>(), isA<InvoiceListLoaded>()],
    );

    blocTest<InvoiceBloc, InvoiceState>(
      'emits [InvoiceLoading, InvoiceError] when load fails',
      build: () {
        when(() => mockRepository.getInvoices(page: any(named: 'page')))
            .thenThrow(Exception('Failed'));
        return invoiceBloc;
      },
      act: (bloc) => bloc.add(const LoadInvoices()),
      expect: () => [isA<InvoiceLoading>(), isA<InvoiceError>()],
    );

    blocTest<InvoiceBloc, InvoiceState>(
      'emits [InvoiceLoading, InvoiceDetailLoaded] when detail succeeds',
      build: () {
        when(() => mockRepository.getInvoiceDetail(any())).thenAnswer((_) async => testInvoice);
        return invoiceBloc;
      },
      act: (bloc) => bloc.add(const LoadInvoiceDetail(id: 1)),
      expect: () => [isA<InvoiceLoading>(), isA<InvoiceDetailLoaded>()],
    );
  });
}
