class AppConfig {
  static const String appName = 'EventFlow';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;

  static const String env = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static bool get isProduction => env == 'production';
  static bool get isStaging => env == 'staging';
  static bool get isDevelopment => env == 'development';

  /// Canonical API base URL — the single source of truth for the whole app.
  ///
  /// Resolution order: `--dart-define=API_BASE_URL` (build time) > this default.
  /// There is deliberately no `.env` loading: `flutter_dotenv` is not a
  /// dependency, so `mobile_app/.env` is never read. Configure the API with a
  /// `--dart-define`, not a dotenv file.
  ///
  /// The value is normalised through [normalizeBaseUrl].
  static String get apiBaseUrl => normalizeBaseUrl(
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://eventflow.baseify.in/api/v1/',
        ),
      );

  /// Ensures a base URL ends with exactly one trailing `/`, or stays empty.
  ///
  /// Call sites such as `InvoiceRemoteDataSource.invoicePdfUrl` build absolute
  /// URLs by plain string concatenation (`'$baseUrl$relativePath'`), so a
  /// define supplied without a trailing slash would otherwise silently
  /// produce a malformed path like `.../api/v1invoices/3/pdf/`.
  ///
  /// Empty input is returned unchanged so an intentionally-unset base URL
  /// stays distinguishable from a real one.
  static String normalizeBaseUrl(String raw) {
    if (raw.isEmpty) return raw;
    return raw.endsWith('/') ? raw : '$raw/';
  }

  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );

  /// Base URL of the hosted web app (matches frontend/.env.production
  /// NEXT_PUBLIC_APP_URL). Used for legal pages opened from the app.
  static const String webBaseUrl = 'https://app.eventflow.com';

  static const String privacyPolicyUrl = '$webBaseUrl/privacy-policy';
  static const String termsUrl = '$webBaseUrl/terms-of-service';
}
