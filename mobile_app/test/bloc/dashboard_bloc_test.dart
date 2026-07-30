import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:eventflow_app/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:eventflow_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:eventflow_app/features/dashboard/data/models/dashboard_model.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late DashboardBloc dashboardBloc;
  late MockDashboardRepository mockRepository;

  setUp(() {
    mockRepository = MockDashboardRepository();
    dashboardBloc = DashboardBloc(repository: mockRepository);
  });

  tearDown(() {
    dashboardBloc.close();
  });

  final testDashboard = DashboardModel(
    totalRevenue: 100000, totalBookings: 50, activeBookings: 20,
    totalCustomers: 100, totalLeads: 30, pendingPayments: 15000,
    occupancyRate: 75, recentBookings: [], upcomingEvents: [], monthlyRevenue: [],
  );

  group('DashboardBloc', () {
    test('initial state is DashboardInitial', () {
      expect(dashboardBloc.state, isA<DashboardInitial>());
    });

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardLoaded] when load succeeds',
      build: () {
        when(() => mockRepository.getSummary()).thenAnswer((_) async => testDashboard);
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(LoadDashboard()),
      expect: () => [isA<DashboardLoading>(), isA<DashboardLoaded>()],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoading, DashboardError] when load fails',
      build: () {
        when(() => mockRepository.getSummary()).thenThrow(Exception('Failed'));
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(LoadDashboard()),
      expect: () => [isA<DashboardLoading>(), isA<DashboardError>()],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardLoaded] when refresh succeeds',
      build: () {
        when(() => mockRepository.getSummary()).thenAnswer((_) async => testDashboard);
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(RefreshDashboard()),
      expect: () => [isA<DashboardLoaded>()],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits [DashboardError] when refresh fails',
      build: () {
        when(() => mockRepository.getSummary()).thenThrow(Exception('Failed'));
        return dashboardBloc;
      },
      act: (bloc) => bloc.add(RefreshDashboard()),
      expect: () => [isA<DashboardError>()],
    );
  });
}
