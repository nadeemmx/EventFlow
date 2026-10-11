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

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://eventflow.baseify.in/api/v1/',
  );

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
