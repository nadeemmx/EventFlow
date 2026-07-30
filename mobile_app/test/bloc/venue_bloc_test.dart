import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:eventflow_app/features/venues/presentation/bloc/venue_bloc.dart';
import 'package:eventflow_app/features/venues/domain/repositories/venue_repository.dart';
import 'package:eventflow_app/features/venues/data/models/venue_model.dart';
import 'package:eventflow_app/core/api/api_response.dart';

class MockVenueRepository extends Mock implements VenueRepository {}

void main() {
  late VenueBloc venueBloc;
  late MockVenueRepository mockRepository;

  setUp(() {
    mockRepository = MockVenueRepository();
    venueBloc = VenueBloc(repository: mockRepository);
  });

  tearDown(() {
    venueBloc.close();
  });

  final testVenue = VenueModel(
    id: 1, name: 'Grand Hall', venueType: 'HALL', capacity: 500,
    description: 'Test', address: 'Addr', weekdayPrice: 50000,
    weekendPrice: 75000, peakPrice: 100000, status: 'ACTIVE',
    createdAt: '2024-01-01',
  );

  group('VenueBloc', () {
    test('initial state is VenueInitial', () {
      expect(venueBloc.state, isA<VenueInitial>());
    });

    blocTest<VenueBloc, VenueState>(
      'emits [VenuesLoading, VenuesLoaded] when load succeeds',
      build: () {
        when(() => mockRepository.getVenues(page: any(named: 'page')))
            .thenAnswer((_) async => ApiResponse<List<VenueModel>>(
              success: true, message: 'OK', data: [testVenue]));
        return venueBloc;
      },
      act: (bloc) => bloc.add(const LoadVenues()),
      expect: () => [isA<VenuesLoading>(), isA<VenuesLoaded>()],
    );

    blocTest<VenueBloc, VenueState>(
      'emits [VenuesLoading, VenueError] when load fails',
      build: () {
        when(() => mockRepository.getVenues(page: any(named: 'page')))
            .thenThrow(Exception('Failed'));
        return venueBloc;
      },
      act: (bloc) => bloc.add(const LoadVenues()),
      expect: () => [isA<VenuesLoading>(), isA<VenueError>()],
    );

    blocTest<VenueBloc, VenueState>(
      'emits [VenuesLoading, VenueDetailLoaded] when detail succeeds',
      build: () {
        when(() => mockRepository.getVenue(any())).thenAnswer((_) async => testVenue);
        return venueBloc;
      },
      act: (bloc) => bloc.add(const LoadVenueDetail(id: 1)),
      expect: () => [isA<VenuesLoading>(), isA<VenueDetailLoaded>()],
    );
  });
}
