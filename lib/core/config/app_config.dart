class AppConfig {
  const AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://vasadomena.sk',
  );

  static const bool isProduction = bool.fromEnvironment(
    'APP_ENV',
    defaultValue: false,
  );

  static Uri apiUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }
}
