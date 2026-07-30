import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:eventflow_app/features/bookings/presentation/bloc/booking_bloc.dart';
import 'package:eventflow_app/features/bookings/domain/repositories/booking_repository.dart';
import 'package:eventflow_app/features/bookings/data/models/booking_model.dart';
import 'package:eventflow_app/core/api/api_response.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

void main() {
  late MockBookingRepository mockBookingRepository;
  late BookingBloc bookingBloc;

  final testBookings = [
    BookingModel(
      id: 1,
      bookingNumber: 'BK-001',
      customer: 1,
      customerName: 'John Doe',
      eventType: 'Wedding',
      eventDate: '2026-01-15',
      guestCount: 200,
      totalAmount: 50000.0,
      advanceAmount: 10000.0,
      status: 'CONFIRMED',
    ),
  ];

  final testBooking = BookingModel(
    id: 1,
    bookingNumber: 'BK-001',
    customer: 1,
    customerName: 'John Doe',
    eventType: 'Wedding',
    eventDate: '2026-01-15',
    guestCount: 200,
    totalAmount: 50000.0,
    advanceAmount: 10000.0,
    status: 'CONFIRMED',
  );

  setUpAll(() {
    registerFallbackValue(const LoadBookings());
  });

  setUp(() {
    mockBookingRepository = MockBookingRepository();
    bookingBloc = BookingBloc(repository: mockBookingRepository);
  });

  tearDown(() {
    bookingBloc.close();
  });

  group('BookingBloc', () {
    blocTest<BookingBloc, BookingState>(
      'emits [BookingsLoading, BookingsLoaded] when LoadBookings succeeds',
      build: () {
        when(() => mockBookingRepository.getBookings(
              page: any(named: 'page'),
              search: any(named: 'search'),
              status: any(named: 'status'),
              venue: any(named: 'venue'),
            )).thenAnswer(
          (_) async => ApiResponse<List<BookingModel>>(
            success: true,
            message: 'Success',
            data: testBookings,
            pagination: const PaginationMeta(
              page: 1,
              pageSize: 20,
              totalRecords: 1,
              totalPages: 1,
            ),
          ),
        );
        return BookingBloc(repository: mockBookingRepository);
      },
      act: (bloc) => bloc.add(const LoadBookings()),
      expect: () => [
        BookingsLoading(),
        isA<BookingsLoaded>(),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'emits [BookingsLoading, BookingError] when LoadBookings fails',
      build: () {
        when(() => mockBookingRepository.getBookings(
              page: any(named: 'page'),
              search: any(named: 'search'),
              status: any(named: 'status'),
              venue: any(named: 'venue'),
            )).thenThrow(Exception('Network error'));
        return BookingBloc(repository: mockBookingRepository);
      },
      act: (bloc) => bloc.add(const LoadBookings()),
      expect: () => [
        BookingsLoading(),
        isA<BookingError>(),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'emits [BookingsLoading, BookingDetailLoaded] when LoadBookingDetail succeeds',
      build: () {
        when(() => mockBookingRepository.getBooking(any())).thenAnswer(
          (_) async => testBooking,
        );
        return BookingBloc(repository: mockBookingRepository);
      },
      act: (bloc) => bloc.add(const LoadBookingDetail(id: 1)),
      expect: () => [
        BookingsLoading(),
        BookingDetailLoaded(booking: testBooking),
      ],
    );
  });
}
