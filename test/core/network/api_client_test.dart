import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:samosprava_bytov/core/config/app_config.dart';
import 'package:samosprava_bytov/core/network/api_client.dart';

void main() {
  test('apiUri preserves the configured installation subdirectory', () {
    final configuredPath = Uri.parse(AppConfig.baseUrl).path;
    final expectedPrefix =
        configuredPath.endsWith('/') ? configuredPath : '$configuredPath/';

    expect(
      AppConfig.apiUri('/api/oznamy.php').path,
      '${expectedPrefix}api/oznamy.php',
    );
  });

  test('getJson accepts a top-level JSON list', () async {
    final client = ApiClient(
      client: MockClient((request) async {
        expect(request.url, AppConfig.apiUri('/api/oznamy.php'));
        return http.Response(
          '[{"nadpis":"Oznam","obsah":"Text"}]',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await client.getJson('/api/oznamy.php');

    expect(result, isA<List<dynamic>>());
    expect((result as List).single, containsPair('nadpis', 'Oznam'));
  });
}
