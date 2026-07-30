import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:eventflow_app/features/bookings/presentation/bloc/booking_bloc.dart';
import 'package:eventflow_app/features/bookings/domain/repositories/booking_repository.dart';
import 'package:eventflow_app/features/bookings/data/models/booking_model.dart';
import 'package:eventflow_app/core/api/api_response.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

void main() {
  late BookingBloc bookingBloc;
  late MockBookingRepository mockRepository;

  setUp(() {
    mockRepository = MockBookingRepository();
    bookingBloc = BookingBloc(repository: mockRepository);
  });

  tearDown(() {
    bookingBloc.close();
  });

  final testBooking = BookingModel(
    id: 1, bookingNumber: 'BK-001', venue: 1, venueName: 'Grand Hall',
    customer: 1, customerName: 'John', package: null, eventType: 'WEDDING',
    eventDate: '2024-03-15', guestCount: 200, totalAmount: 50000,
    advanceAmount: 10000, status: 'CONFIRMED',
  );

  group('BookingBloc', () {
    test('initial state is BookingInitial', () {
      expect(bookingBloc.state, isA<BookingInitial>());
    });

    blocTest<BookingBloc, BookingState>(
      'emits [BookingsLoading, BookingsLoaded] when load succeeds',
      build: () {
        when(() => mockRepository.getBookings(page: any(named: 'page')))
            .thenAnswer((_) async => ApiResponse<List<BookingModel>>(
              success: true, message: 'OK', data: [testBooking]));
        return bookingBloc;
      },
      act: (bloc) => bloc.add(const LoadBookings()),
      expect: () => [isA<BookingsLoading>(), isA<BookingsLoaded>()],
    );

    blocTest<BookingBloc, BookingState>(
      'emits [BookingsLoading, BookingError] when load fails',
      build: () {
        when(() => mockRepository.getBookings(page: any(named: 'page')))
            .thenThrow(Exception('Failed'));
        return bookingBloc;
      },
      act: (bloc) => bloc.add(const LoadBookings()),
      expect: () => [isA<BookingsLoading>(), isA<BookingError>()],
    );

    blocTest<BookingBloc, BookingState>(
      'emits [BookingsLoading, BookingDetailLoaded] when load detail succeeds',
      build: () {
        when(() => mockRepository.getBooking(any())).thenAnswer((_) async => testBooking);
        return bookingBloc;
      },
      act: (bloc) => bloc.add(const LoadBookingDetail(id: 1)),
      expect: () => [isA<BookingsLoading>(), isA<BookingDetailLoaded>()],
    );

    blocTest<BookingBloc, BookingState>(
      'emits [BookingsLoading, BookingActionSuccess] when create succeeds',
      build: () {
        when(() => mockRepository.createBooking(any())).thenAnswer((_) async => testBooking);
        return bookingBloc;
      },
      act: (bloc) => bloc.add(const CreateBooking(data: {})),
      expect: () => [isA<BookingsLoading>(), isA<BookingActionSuccess>()],
    );

    blocTest<BookingBloc, BookingState>(
      'emits [BookingsLoading, BookingActionSuccess] when update succeeds',
      build: () {
        when(() => mockRepository.updateBooking(any(), any())).thenAnswer((_) async => testBooking);
        return bookingBloc;
      },
      act: (bloc) => bloc.add(const UpdateBooking(id: 1, data: {})),
      expect: () => [isA<BookingsLoading>(), isA<BookingActionSuccess>()],
    );
  });
}
