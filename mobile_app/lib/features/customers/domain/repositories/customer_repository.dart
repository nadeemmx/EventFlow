import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/core/storage/storage_service.dart';
import 'package:eventflow_app/core/network/network_info.dart';
import 'package:eventflow_app/features/customers/data/datasources/customer_remote_data_source.dart';
import 'package:eventflow_app/features/customers/data/models/customer_model.dart';

class CustomerRepository {
  final CustomerRemoteDataSource _remoteDataSource;
  final StorageService _storageService;
  final NetworkInfo _networkInfo;

  CustomerRepository({
    required this._remoteDataSource,
    required this._storageService,
    required this._networkInfo,
  });

  Future<ApiResponse<List<CustomerModel>>> getCustomers({int page = 1, String? search}) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getCustomers(page: page, search: search);
        if (page == 1) {
          final items = response.data ?? [];
          await _storageService.cacheJson('cache_customers', items.map((c) => {
            'id': c.id,
            'full_name': c.fullName,
            'mobile': c.mobile,
            'email': c.email,
            'address': c.address,
            'remarks': c.remarks,
            'created_at': c.createdAt,
          }).toList());
        }
        return response;
      } catch (_) {
        final cached = _getCachedCustomers();
        if (cached.isNotEmpty) {
          return ApiResponse<List<CustomerModel>>(
            success: true,
            message: 'Loaded from cache',
            data: cached,
          );
        }
        rethrow;
      }
    }
    final cached = _getCachedCustomers();
    if (cached.isNotEmpty) {
      return ApiResponse<List<CustomerModel>>(
        success: true,
        message: 'Loaded from cache',
        data: cached,
      );
    }
    throw Exception('No internet connection and no cached data');
  }

  Future<CustomerModel> getCustomer(int id) => _remoteDataSource.getCustomer(id);

  Future<CustomerModel> createCustomer(Map<String, dynamic> data) => _remoteDataSource.createCustomer(data);

  Future<CustomerModel> updateCustomer(int id, Map<String, dynamic> data) => _remoteDataSource.updateCustomer(id, data);

  Future<void> uploadAttachment(int customerId, String filePath, String label) =>
      _remoteDataSource.uploadCustomerAttachment(customerId, filePath, label);

  List<CustomerModel> _getCachedCustomers() {
    return _storageService.getCachedJsonList('cache_customers', (data) {
      return CustomerModel.fromJson(data);
    });
  }
}
