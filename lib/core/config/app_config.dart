class AppConfig {
  const AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://sb.chudy.online',
  );

  static const bool isProduction = bool.fromEnvironment(
    'APP_ENV',
    defaultValue: false,
  );

  static Uri apiUri(String path) {
    final baseUri = Uri.parse(
      baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
    );
    final relativePath = path.startsWith('/') ? path.substring(1) : path;
    return baseUri.resolve(relativePath);
  }
}
