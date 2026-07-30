import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/core/storage/storage_service.dart';
import 'package:eventflow_app/core/network/network_info.dart';
import 'package:eventflow_app/features/leads/data/datasources/lead_remote_data_source.dart';
import 'package:eventflow_app/features/leads/data/models/lead_model.dart';

class LeadRepository {
  final LeadRemoteDataSource _remoteDataSource;
  final StorageService _storageService;
  final NetworkInfo _networkInfo;

  LeadRepository({
    required this._remoteDataSource,
    required this._storageService,
    required this._networkInfo,
  });

  Future<ApiResponse<List<LeadModel>>> getLeads({int page = 1, String? search}) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getLeads(page: page, search: search);
        if (page == 1) {
          final items = response.data ?? [];
          await _storageService.cacheJson('cache_leads', items.map((l) => {
            'id': l.id,
            'customer': l.customer,
            'customer_name': l.customerName,
            'lead_source': l.leadSource,
            'event_type': l.eventType,
            'expected_event_date': l.expectedEventDate,
            'expected_guest_count': l.expectedGuestCount,
            'lead_status': l.leadStatus,
            'assigned_to': l.assignedTo,
            'created_at': l.createdAt,
          }).toList());
        }
        return response;
      } catch (_) {
        final cached = _getCachedLeads();
        if (cached.isNotEmpty) {
          return ApiResponse<List<LeadModel>>(
            success: true,
            message: 'Loaded from cache',
            data: cached,
          );
        }
        rethrow;
      }
    }
    final cached = _getCachedLeads();
    if (cached.isNotEmpty) {
      return ApiResponse<List<LeadModel>>(
        success: true,
        message: 'Loaded from cache',
        data: cached,
      );
    }
    throw Exception('No internet connection and no cached data');
  }

  Future<LeadModel> getLead(int id) => _remoteDataSource.getLead(id);

  Future<LeadModel> createLead(Map<String, dynamic> data) => _remoteDataSource.createLead(data);

  Future<LeadModel> updateLead(int id, Map<String, dynamic> data) => _remoteDataSource.updateLead(id, data);

  Future<LeadModel> convertLead(int id, int venueId) => _remoteDataSource.convertLead(id, venueId);

  List<LeadModel> _getCachedLeads() {
    return _storageService.getCachedJsonList('cache_leads', (data) {
      return LeadModel.fromJson(data);
    });
  }
}
