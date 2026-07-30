import 'package:eventflow_app/core/api/api_client.dart';
import 'package:eventflow_app/core/api/api_endpoints.dart';
import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/features/leads/data/models/lead_model.dart';

class LeadRemoteDataSource {
  final ApiClient _apiClient;

  LeadRemoteDataSource({required this._apiClient});

  Future<ApiResponse<List<LeadModel>>> getLeads({int page = 1, String? search}) async {
    final params = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final response = await _apiClient.get(ApiEndpoints.leads, queryParameters: params);
    return ApiResponse.fromJsonList(
      response.data as Map<String, dynamic>,
      LeadModel.fromJson,
    );
  }

  Future<LeadModel> getLead(int id) async {
    final response = await _apiClient.get(ApiEndpoints.leadDetail(id));
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => LeadModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) throw Exception(apiResponse.message);
    return apiResponse.data!;
  }

  Future<LeadModel> createLead(Map<String, dynamic> data) async {
    final response = await _apiClient.post(ApiEndpoints.leads, data: data);
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => LeadModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) throw Exception(apiResponse.message);
    return apiResponse.data!;
  }

  Future<LeadModel> updateLead(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(ApiEndpoints.leadDetail(id), data: data);
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => LeadModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) throw Exception(apiResponse.message);
    return apiResponse.data!;
  }

  Future<LeadModel> convertLead(int id, int venueId) async {
    final response = await _apiClient.post(ApiEndpoints.leadConvert(id), data: {'venue_id': venueId});
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => LeadModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) throw Exception(apiResponse.message);
    return apiResponse.data!;
  }
}
