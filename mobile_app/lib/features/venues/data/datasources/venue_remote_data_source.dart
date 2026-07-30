import 'package:dio/dio.dart';
import 'package:eventflow_app/core/api/api_client.dart';
import 'package:eventflow_app/core/api/api_endpoints.dart';
import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/features/venues/data/models/venue_model.dart';

class VenueRemoteDataSource {
  final ApiClient _apiClient;

  VenueRemoteDataSource({required this._apiClient});

  Future<ApiResponse<List<VenueModel>>> getVenues({int page = 1}) async {
    final response = await _apiClient.get(
      ApiEndpoints.venues,
      queryParameters: {'page': page},
    );
    return ApiResponse.fromJsonList(
      response.data as Map<String, dynamic>,
      VenueModel.fromJson,
    );
  }

  Future<VenueModel> getVenue(int id) async {
    final response = await _apiClient.get(ApiEndpoints.venueDetail(id));
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => VenueModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }

  Future<void> uploadVenueImage(int venueId, String filePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });
    await _apiClient.post(
      ApiEndpoints.venueImages(venueId),
      data: formData,
    );
  }
}
