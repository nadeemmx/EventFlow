import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/core/storage/storage_service.dart';
import 'package:eventflow_app/core/network/network_info.dart';
import 'package:eventflow_app/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:eventflow_app/features/bookings/data/models/booking_model.dart';

class BookingRepository {
  final BookingRemoteDataSource _remoteDataSource;
  final StorageService _storageService;
  final NetworkInfo _networkInfo;

  BookingRepository({
    required this._remoteDataSource,
    required this._storageService,
    required this._networkInfo,
  });

  Future<ApiResponse<List<BookingModel>>> getBookings({int page = 1, String? search, String? status, int? venue}) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getBookings(page: page, search: search, status: status, venue: venue);
        if (page == 1) {
          final items = response.data ?? [];
          await _storageService.cacheJson('cache_bookings', items.map((b) => {
            'id': b.id,
            'booking_number': b.bookingNumber,
            'venue': b.venue,
            'venue_name': b.venueName,
            'customer': b.customer,
            'customer_name': b.customerName,
            'package': b.package,
            'event_type': b.eventType,
            'event_date': b.eventDate,
            'guest_count': b.guestCount,
            'total_amount': b.totalAmount,
            'advance_amount': b.advanceAmount,
            'status': b.status,
            'remarks': b.remarks,
            'created_at': b.createdAt,
          }).toList());
        }
        return response;
      } catch (_) {
        final cached = _getCachedBookings();
        if (cached.isNotEmpty) {
          return ApiResponse<List<BookingModel>>(
            success: true,
            message: 'Loaded from cache',
            data: cached,
          );
        }
        rethrow;
      }
    }
    final cached = _getCachedBookings();
    if (cached.isNotEmpty) {
      return ApiResponse<List<BookingModel>>(
        success: true,
        message: 'Loaded from cache',
        data: cached,
      );
    }
    throw Exception('No internet connection and no cached data');
  }

  Future<BookingModel> getBooking(int id) async {
    return await _remoteDataSource.getBooking(id);
  }

  Future<BookingModel> createBooking(Map<String, dynamic> data) async {
    return await _remoteDataSource.createBooking(data);
  }

  Future<BookingModel> updateBooking(int id, Map<String, dynamic> data) async {
    return await _remoteDataSource.updateBooking(id, data);
  }

  Future<BookingModel> confirmBooking(int id) async {
    return await _remoteDataSource.confirmBooking(id);
  }

  Future<BookingModel> cancelBooking(int id, {String? remarks}) async {
    return await _remoteDataSource.cancelBooking(id, remarks: remarks);
  }

  Future<BookingModel> markInProgress(int id) async {
    return await _remoteDataSource.markInProgress(id);
  }

  Future<BookingModel> markCompleted(int id) async {
    return await _remoteDataSource.markCompleted(id);
  }

  List<BookingModel> _getCachedBookings() {
    return _storageService.getCachedJsonList('cache_bookings', (data) {
      return BookingModel.fromJson(data);
    });
  }
}
