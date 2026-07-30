import 'package:eventflow_app/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:eventflow_app/features/authentication/data/models/login_response_model.dart';
import 'package:eventflow_app/features/authentication/data/models/user_model.dart';
import 'package:eventflow_app/core/services/token_service.dart';
import 'package:eventflow_app/core/services/guest_session_service.dart';
import 'package:eventflow_app/core/services/demo_data_provider.dart';

class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final TokenService _tokenService;
  final GuestSessionService _guestSessionService;

  AuthRepository({
    required this._remoteDataSource,
    required this._tokenService,
    required this._guestSessionService,
  });

  Future<LoginResponseModel> login(String email, String password) async {
    final loginResponse = await _remoteDataSource.login(email, password);
    await _tokenService.saveAccessToken(loginResponse.accessToken);
    await _tokenService.saveRefreshToken(loginResponse.refreshToken);
    return loginResponse;
  }

  Future<void> forgotPassword(String email) async {
    await _remoteDataSource.forgotPassword(email);
  }

  Future<void> resetPassword(String token, String password, String confirmPassword) async {
    await _remoteDataSource.resetPassword(token, password, confirmPassword);
  }

  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    await _remoteDataSource.changePassword(currentPassword, newPassword, confirmPassword);
  }

  Future<UserModel> getProfile() async {
    return await _remoteDataSource.getProfile();
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    return await _remoteDataSource.updateProfile(data);
  }

  Future<UserModel> uploadProfileImage(String filePath) async {
    return await _remoteDataSource.uploadProfileImage(filePath);
  }

  Future<void> logout() async {
    await _tokenService.clearTokens();
    await _guestSessionService.endSession();
  }

  Future<bool> isLoggedIn() async {
    return await _tokenService.isLoggedIn();
  }

  Future<UserModel> guestLogin() async {
    await _guestSessionService.startSession();
    return DemoDataProvider().guestUser;
  }

  Future<void> guestLogout() async {
    await _guestSessionService.endSession();
  }

  Future<bool> isGuest() async {
    return _guestSessionService.isGuestSession();
  }
}
