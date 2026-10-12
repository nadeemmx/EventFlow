import 'package:flutter_test/flutter_test.dart';

import 'package:eventflow_app/core/config/app_config.dart';
import 'package:eventflow_app/core/api/api_endpoints.dart';

/// Regression tests for fix M-1 (base URL single source of truth).
///
/// Before M-1 the app declared `API_BASE_URL` twice with different defaults:
///
///   * `AppConfig.apiBaseUrl`        -> https://eventflow.baseify.in/api/v1/
///   * `ApiEndpoints.baseUrl`        -> http://31.42.125.6/api/v1/  (plaintext!)
///
/// `ApiClient` reads `ApiEndpoints.baseUrl`, so the raw-IP plaintext default
/// was the one actually in effect. These tests pin the invariants that keep
/// the two declarations from drifting apart again.
void main() {
  group('M-1: API base URL single source of truth', () {
    test('ApiEndpoints.baseUrl reads from AppConfig rather than redeclaring it',
        () {
      expect(ApiEndpoints.baseUrl, AppConfig.apiBaseUrl);
    });

    test('default base URL is HTTPS, not plaintext HTTP', () {
      expect(AppConfig.apiBaseUrl, startsWith('https://'));
      expect(AppConfig.apiBaseUrl, isNot(startsWith('http://')));
    });

    test('default base URL contains no hardcoded raw IP address', () {
      // The pre-M-1 default pointed at a raw IPv4 host over plaintext HTTP.
      expect(AppConfig.apiBaseUrl, isNot(contains('31.42.125.6')));
      expect(AppConfig.apiBaseUrl, matches(RegExp(r'https://[a-zA-Z]')));
    });

    test('default base URL ends with a trailing slash', () {
      // InvoiceRemoteDataSource builds absolute URLs by concatenation, so a
      // missing slash silently corrupts the path.
      expect(AppConfig.apiBaseUrl.endsWith('/'), isTrue);
    });
  });

  group('M-1: normalizeBaseUrl', () {
    test('appends a trailing slash when missing', () {
      expect(
        AppConfig.normalizeBaseUrl('https://api.example.com/api/v1'),
        'https://api.example.com/api/v1/',
      );
    });

    test('leaves an existing trailing slash untouched', () {
      expect(
        AppConfig.normalizeBaseUrl('https://api.example.com/api/v1/'),
        'https://api.example.com/api/v1/',
      );
    });

    test('never produces a trailing double slash', () {
      final result = AppConfig.normalizeBaseUrl('https://api.example.com/v1');
      expect(result, 'https://api.example.com/v1/');
      expect(result.endsWith('//'), isFalse);
    });

    test('returns empty input unchanged so unset stays distinguishable', () {
      expect(AppConfig.normalizeBaseUrl(''), '');
    });

    test('is idempotent', () {
      final once = AppConfig.normalizeBaseUrl('https://x.example/v1');
      expect(AppConfig.normalizeBaseUrl(once), once);
    });
  });
}
