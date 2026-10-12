import 'package:dio/dio.dart';
import 'package:eventflow_app/core/api/api_client.dart';
import 'package:eventflow_app/core/api/api_endpoints.dart';
import 'package:eventflow_app/core/api/api_response.dart';
import 'package:eventflow_app/features/authentication/data/models/login_response_model.dart';
import 'package:eventflow_app/features/authentication/data/models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource({required this._apiClient});

  Future<LoginResponseModel> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => LoginResponseModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }

  Future<LoginResponseModel> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required bool termsAccepted,
    required bool privacyAccepted,
    required bool ageConfirmed,
    bool marketingOptIn = false,
    String? mobile,
  }) async {
    final data = <String, dynamic>{
      'full_name': fullName,
      'email': email,
      'password': password,
      'confirm_password': confirmPassword,
      'terms_accepted': termsAccepted,
      'privacy_accepted': privacyAccepted,
      'age_confirmed': ageConfirmed,
      'marketing_opt_in': marketingOptIn,
    };
    if (mobile != null && mobile.isNotEmpty) {
      data['mobile'] = mobile;
    }
    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: data,
    );
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => LoginResponseModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }

  /// Revokes the session server-side (`POST auth/logout/`).
  ///
  /// The backend `LogoutView` requires an authenticated request plus a
  /// `refresh_token` body field (see `RefreshSerializer`); the access token is
  /// attached by the ApiClient auth interceptor.
  Future<void> logout(String refreshToken) async {
    await _apiClient.post(
      ApiEndpoints.logout,
      data: {'refresh_token': refreshToken},
    );
  }

  Future<ApiResponse<void>> forgotPassword(String email) async {
    final response = await _apiClient.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
    return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
  }

  Future<ApiResponse<void>> resetPassword(String token, String password, String confirmPassword) async {
    final response = await _apiClient.post(
      ApiEndpoints.resetPassword,
      data: {
        'token': token,
        'password': password,
        'confirm_password': confirmPassword,
      },
    );
    return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
  }

  Future<ApiResponse<void>> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    final response = await _apiClient.post(
      ApiEndpoints.changePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
    return ApiResponse.fromJson(response.data as Map<String, dynamic>, null);
  }

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.profile);
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.put(ApiEndpoints.profile, data: data);
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }

  Future<UserModel> uploadProfileImage(String filePath) async {
    final formData = FormData.fromMap({
      'profile_image': await MultipartFile.fromFile(filePath),
    });
    final response = await _apiClient.post(
      '${ApiEndpoints.profile}upload_image/',
      data: formData,
    );
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => UserModel.fromJson(data as Map<String, dynamic>),
    );
    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message);
    }
    return apiResponse.data!;
  }
}
