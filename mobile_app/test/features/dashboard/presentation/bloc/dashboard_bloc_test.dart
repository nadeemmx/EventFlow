import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:eventflow_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:eventflow_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:eventflow_app/features/dashboard/data/models/dashboard_model.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late MockDashboardRepository mockDashboardRepository;
  late DashboardBloc dashboardBloc;

  final testDashboard = DashboardModel(
    totalRevenue: 500000.0,
    totalBookings: 45,
    activeBookings: 12,
    totalCustomers: 30,
    totalLeads: 55,
    pendingPayments: 75000.0,
    occupancyRate: 68.5,
    recentBookings: [],
    upcomingEvents: [],
    monthlyRevenue: [],
  );

  setUpAll(() {
    registerFallbackValue(LoadDashboard());
  });

  setUp(() {
    mockDashboardRepository = MockDashboardRepository();
    dashboardBloc = DashboardBloc(repository: mockDashboardRepository);
  });

  tearDown(() {
    dashboardBloc.close();
  });

  group('DashboardBloc', () {
    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardLoaded] when LoadDashboard succeeds',
      build: () {
        when(() => mockDashboardRepository.getSummary()).thenAnswer(
          (_) async => testDashboard,
        );
        return DashboardBloc(repository: mockDashboardRepository);
      },
      act: (bloc) => bloc.add(LoadDashboard()),
      expect: () => [
        DashboardLoading(),
        DashboardLoaded(dashboard: testDashboard),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardError] when LoadDashboard fails',
      build: () {
        when(() => mockDashboardRepository.getSummary()).thenThrow(
          Exception('Failed to load dashboard'),
        );
        return DashboardBloc(repository: mockDashboardRepository);
      },
      act: (bloc) => bloc.add(LoadDashboard()),
      expect: () => [
        DashboardLoading(),
        isA<DashboardError>(),
      ],
    );
  });
}
