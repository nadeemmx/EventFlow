import 'package:eventflow_app/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:eventflow_app/features/authentication/data/models/login_response_model.dart';
import 'package:eventflow_app/features/authentication/data/models/user_model.dart';
import 'package:eventflow_app/core/services/token_service.dart';
import 'package:eventflow_app/core/services/guest_session_service.dart';
import 'package:eventflow_app/core/services/notification_service.dart';
import 'package:eventflow_app/core/services/demo_data_provider.dart';
import 'package:eventflow_app/core/storage/storage_service.dart';

class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final TokenService _tokenService;
  final GuestSessionService _guestSessionService;
  final StorageService _storageService;
  final NotificationService _notificationService;

  AuthRepository({
    required this._remoteDataSource,
    required this._tokenService,
    required this._guestSessionService,
    required this._storageService,
    required this._notificationService,
  });

  Future<LoginResponseModel> login(String email, String password) async {
    final loginResponse = await _remoteDataSource.login(email, password);
    await _tokenService.saveAccessToken(loginResponse.accessToken);
    await _tokenService.saveRefreshToken(loginResponse.refreshToken);
    return loginResponse;
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
    final loginResponse = await _remoteDataSource.register(
      fullName: fullName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      termsAccepted: termsAccepted,
      privacyAccepted: privacyAccepted,
      ageConfirmed: ageConfirmed,
      marketingOptIn: marketingOptIn,
      mobile: mobile,
    );
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
    // 1. Best-effort server-side revocation. The API call must never prevent
    //    local sign-out (fail silently), so every error is swallowed here.
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _remoteDataSource.logout(refreshToken);
      }
    } catch (_) {
      // Server unreachable / already revoked — still clear local state.
    }

    // 2. Drop the session.
    try {
      await _tokenService.clearTokens();
    } catch (_) {
      // Never block sign-out on secure-storage errors.
    }
    try {
      await _guestSessionService.endSession();
    } catch (_) {
      // Best effort.
    }

    // 3. Purge cached customer/booking/lead data (Hive `cache_*` keys) so no
    //    tenant data survives a logout.
    try {
      await _storageService.clearCache();
    } catch (_) {
      // Best effort.
    }

    // 4. Drop this device's FCM token. There is no backend unregister
    //    endpoint (apps/notifications only exposes list/mark_read), so the
    //    token is only removed locally.
    try {
      await _notificationService.deleteToken();
    } catch (_) {
      // Firebase may be unavailable (e.g. missing google-services config).
    }
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
