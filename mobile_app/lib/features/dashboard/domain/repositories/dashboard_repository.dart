import 'package:eventflow_app/core/storage/storage_service.dart';
import 'package:eventflow_app/core/network/network_info.dart';
import 'package:eventflow_app/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:eventflow_app/features/dashboard/data/models/dashboard_model.dart';

class DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;
  final StorageService _storageService;
  final NetworkInfo _networkInfo;

  DashboardRepository({
    required this._remoteDataSource,
    required this._storageService,
    required this._networkInfo,
  });

  Future<DashboardModel> getSummary() async {
    if (await _networkInfo.isConnected) {
      try {
        final dashboard = await _remoteDataSource.getSummary();
        await _storageService.cacheJson('cache_dashboard', {
          'total_revenue': dashboard.totalRevenue,
          'total_bookings': dashboard.totalBookings,
          'active_bookings': dashboard.activeBookings,
          'total_customers': dashboard.totalCustomers,
          'total_leads': dashboard.totalLeads,
          'pending_payments': dashboard.pendingPayments,
          'occupancy_rate': dashboard.occupancyRate,
          'recent_bookings': dashboard.recentBookings.map((b) => {
            'id': b.id,
            'booking_number': b.bookingNumber,
            'customer_name': b.customerName,
            'event_date': b.eventDate,
            'status': b.status,
            'total_amount': b.totalAmount,
          }).toList(),
          'upcoming_events': dashboard.upcomingEvents.map((e) => {
            'id': e.id,
            'booking_number': e.bookingNumber,
            'customer_name': e.customerName,
            'event_date': e.eventDate,
            'venue_name': e.venueName,
          }).toList(),
          'monthly_revenue': dashboard.monthlyRevenue.map((m) => {
            'month': m.month,
            'amount': m.amount,
          }).toList(),
        });
        return dashboard;
      } catch (_) {
        final cached = _getCached();
        if (cached != null) return cached;
        rethrow;
      }
    }
    final cached = _getCached();
    if (cached != null) return cached;
    throw Exception('No internet connection and no cached data');
  }

  DashboardModel? _getCached() {
    return _storageService.getCachedJson('cache_dashboard', (data) {
      return DashboardModel.fromJson(data as Map<String, dynamic>);
    });
  }
}
