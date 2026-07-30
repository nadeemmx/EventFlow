import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:eventflow_app/features/leads/presentation/bloc/lead_bloc.dart';
import 'package:eventflow_app/features/leads/domain/repositories/lead_repository.dart';
import 'package:eventflow_app/features/leads/data/models/lead_model.dart';
import 'package:eventflow_app/core/api/api_response.dart';

class MockLeadRepository extends Mock implements LeadRepository {}

void main() {
  late LeadBloc leadBloc;
  late MockLeadRepository mockRepository;

  setUp(() {
    mockRepository = MockLeadRepository();
    leadBloc = LeadBloc(repository: mockRepository);
  });

  tearDown(() {
    leadBloc.close();
  });

  final testLead = LeadModel(
    id: 1, customer: 1, customerName: 'John', leadSource: 'WEBSITE',
    eventType: 'WEDDING', expectedEventDate: '2024-06-01',
    expectedGuestCount: 200, leadStatus: 'NEW', createdAt: '2024-01-01',
  );

  group('LeadBloc', () {
    test('initial state is LeadInitial', () {
      expect(leadBloc.state, isA<LeadInitial>());
    });

    blocTest<LeadBloc, LeadState>(
      'emits [LeadsLoading, LeadsLoaded] when load succeeds',
      build: () {
        when(() => mockRepository.getLeads(page: any(named: 'page')))
            .thenAnswer((_) async => ApiResponse<List<LeadModel>>(
              success: true, message: 'OK', data: [testLead]));
        return leadBloc;
      },
      act: (bloc) => bloc.add(const LoadLeads()),
      expect: () => [isA<LeadsLoading>(), isA<LeadsLoaded>()],
    );

    blocTest<LeadBloc, LeadState>(
      'emits [LeadsLoading, LeadError] when load fails',
      build: () {
        when(() => mockRepository.getLeads(page: any(named: 'page')))
            .thenThrow(Exception('Failed'));
        return leadBloc;
      },
      act: (bloc) => bloc.add(const LoadLeads()),
      expect: () => [isA<LeadsLoading>(), isA<LeadError>()],
    );

    blocTest<LeadBloc, LeadState>(
      'emits [LeadsLoading, LeadDetailLoaded] when detail succeeds',
      build: () {
        when(() => mockRepository.getLead(any())).thenAnswer((_) async => testLead);
        return leadBloc;
      },
      act: (bloc) => bloc.add(const LoadLeadDetail(id: 1)),
      expect: () => [isA<LeadsLoading>(), isA<LeadDetailLoaded>()],
    );

    blocTest<LeadBloc, LeadState>(
      'emits [LeadsLoading, LeadActionSuccess] when create succeeds',
      build: () {
        when(() => mockRepository.createLead(any())).thenAnswer((_) async => testLead);
        return leadBloc;
      },
      act: (bloc) => bloc.add(const CreateLead(data: {})),
      expect: () => [isA<LeadsLoading>(), isA<LeadActionSuccess>()],
    );

    blocTest<LeadBloc, LeadState>(
      'emits [LeadsLoading, LeadActionSuccess] when convert succeeds',
      build: () {
        when(() => mockRepository.convertLead(any(), any())).thenAnswer((_) async => testLead);
        return leadBloc;
      },
      act: (bloc) => bloc.add(const ConvertLead(id: 1, venueId: 1)),
      expect: () => [isA<LeadsLoading>(), isA<LeadActionSuccess>()],
    );
  });
}
