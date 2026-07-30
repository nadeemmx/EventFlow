import 'package:eventflow_app/core/api/api_client.dart';
import 'package:eventflow_app/core/api/api_endpoints.dart';
import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/features/dashboard/data/models/dashboard_model.dart';

class DashboardRemoteDataSource {
  final ApiClient _apiClient;

  DashboardRemoteDataSource({required this._apiClient});

  Future<DashboardModel> getSummary() async {
    final response = await _apiClient.get(ApiEndpoints.dashboardSummary);
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => DashboardModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }
}
