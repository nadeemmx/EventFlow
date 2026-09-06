import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userDataKey = 'user_data';

  final FlutterSecureStorage _storage;

  TokenService({required this._storage});

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token != null && token.isEmpty) return null;
    return token;
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    final token = await _storage.read(key: _refreshTokenKey);
    if (token != null && token.isEmpty) return null;
    return token;
  }

  Future<void> saveUserData(String userData) async {
    await _storage.write(key: _userDataKey, value: userData);
  }

  Future<String?> getUserData() async {
    final data = await _storage.read(key: _userDataKey);
    if (data != null && data.isEmpty) return null;
    return data;
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userDataKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
