import 'package:eventflow_app/core/api/api_client.dart';
import 'package:eventflow_app/core/api/api_endpoints.dart';
import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/features/bookings/data/models/booking_model.dart';

class BookingRemoteDataSource {
  final ApiClient _apiClient;

  BookingRemoteDataSource({required this._apiClient});

  Future<ApiResponse<List<BookingModel>>> getBookings({
    int page = 1,
    String? search,
    String? status,
    int? venue,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (venue != null) params['venue'] = venue;

    final response = await _apiClient.get(ApiEndpoints.bookings, queryParameters: params);
    return ApiResponse.fromJsonList(
      response.data as Map<String, dynamic>,
      BookingModel.fromJson,
    );
  }

  Future<BookingModel> getBooking(int id) async {
    final response = await _apiClient.get(ApiEndpoints.bookingDetail(id));
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => BookingModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }

  Future<BookingModel> createBooking(Map<String, dynamic> data) async {
    final response = await _apiClient.post(ApiEndpoints.bookings, data: data);
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => BookingModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }

  Future<BookingModel> updateBooking(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(ApiEndpoints.bookingDetail(id), data: data);
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => BookingModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }

  Future<BookingModel> confirmBooking(int id) async {
    final response = await _apiClient.post(ApiEndpoints.bookingConfirm(id));
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => BookingModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }

  Future<BookingModel> cancelBooking(int id, {String? remarks}) async {
    final body = <String, dynamic>{};
    if (remarks != null) body['remarks'] = remarks;
    final response = await _apiClient.post(
      ApiEndpoints.bookingCancel(id),
      data: body.isEmpty ? null : body,
    );
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => BookingModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }

  Future<BookingModel> markInProgress(int id) async {
    final response = await _apiClient.post(ApiEndpoints.bookingMarkInProgress(id));
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => BookingModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }

  Future<BookingModel> markCompleted(int id) async {
    final response = await _apiClient.post(ApiEndpoints.bookingMarkCompleted(id));
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => BookingModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }
}
