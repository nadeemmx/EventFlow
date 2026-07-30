import 'package:dio/dio.dart';
import 'package:eventflow_app/core/api/api_client.dart';
import 'package:eventflow_app/core/api/api_endpoints.dart';
import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/features/customers/data/models/customer_model.dart';

class CustomerRemoteDataSource {
  final ApiClient _apiClient;

  CustomerRemoteDataSource({required this._apiClient});

  Future<ApiResponse<List<CustomerModel>>> getCustomers({int page = 1, String? search}) async {
    final params = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final response = await _apiClient.get(ApiEndpoints.customers, queryParameters: params);
    return ApiResponse.fromJsonList(
      response.data as Map<String, dynamic>,
      CustomerModel.fromJson,
    );
  }

  Future<CustomerModel> getCustomer(int id) async {
    final response = await _apiClient.get(ApiEndpoints.customerDetail(id));
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => CustomerModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) throw Exception(apiResponse.message);
    return apiResponse.data!;
  }

  Future<CustomerModel> createCustomer(Map<String, dynamic> data) async {
    final response = await _apiClient.post(ApiEndpoints.customers, data: data);
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => CustomerModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) throw Exception(apiResponse.message);
    return apiResponse.data!;
  }

  Future<CustomerModel> updateCustomer(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(ApiEndpoints.customerDetail(id), data: data);
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => CustomerModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) throw Exception(apiResponse.message);
    return apiResponse.data!;
  }

  Future<void> uploadCustomerAttachment(int customerId, String filePath, String label) async {
    final formData = FormData.fromMap({
      'attachment': await MultipartFile.fromFile(filePath),
      'label': label,
    });
    await _apiClient.post(
      '${ApiEndpoints.customerDetail(customerId)}attachments/',
      data: formData,
    );
  }
}
