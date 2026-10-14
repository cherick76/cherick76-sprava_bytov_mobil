import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    bool requireAuth = false,
  }) async {
    final response = await _client.post(
      AppConfig.apiUri(path),
      headers: {
        ...headers,
        if (requireAuth && _token == null) 'Authorization': '',
      },
      body: jsonEncode(body),
    );

    return _decodeJsonResponse(response);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    bool requireAuth = false,
  }) async {
    final response = await _client.get(
      AppConfig.apiUri(path),
      headers: {
        ...headers,
        if (requireAuth && _token == null) 'Authorization': '',
      },
    );

    return _decodeJsonResponse(response);
  }

  Future<Map<String, dynamic>> multipart(
    String path,
    Map<String, String> fields, {
    String? fileKey,
    String? filePath,
    String? fileName,
  }) async {
    final request = http.MultipartRequest('POST', AppConfig.apiUri(path));

    request.headers.addAll({
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    });

    fields.forEach(request.fields.addAll);

    if (fileKey != null && filePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          fileKey,
          filePath,
          filename: fileName,
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeJsonResponse(response);
  }

  Map<String, dynamic> _decodeJsonResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    Map<String, dynamic> decoded;

    try {
      final dynamic parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        decoded = parsed;
      } else if (parsed is Map) {
        decoded = parsed.map((key, value) => MapEntry(key.toString(), value));
      } else {
        throw const FormatException('Invalid response payload.');
      }
    } on FormatException {
      throw ApiException('Server vrátil neplatnú odpoveď.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded['sprava'] ?? decoded['chyba'] ?? 'Request failed.';
      throw ApiException(message.toString());
    }

    return decoded;
  }
}
