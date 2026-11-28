import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'api_config.dart';
import 'api_exception.dart';

class HttpApiClient implements ApiClient {
  HttpApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;

    final uri = Uri.parse(ApiConfig.baseUrl).resolve(normalizedPath);

    if (query == null || query.isEmpty) {
      return uri;
    }

    return uri.replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<Map<String, Object?>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(ApiConfig.receiveTimeout);

      final rawBody = response.body;
      final contentType = response.headers['content-type'] ?? 'unknown';

      // Diagnostic: do not print access tokens or passwords.
      final preview = rawBody.replaceAll(RegExp(r'\s+'), ' ');

      developer.log(
        '[AssetOne API] HTTP ${response.statusCode}'
        ' | Content-Type: $contentType'
        ' | Body length: ${rawBody.length}'
        ' | Preview: ${preview.length > 100 ? preview.substring(0, 100) : preview}',
        name: 'AssetOne API',
      );

      Object? body;

      if (rawBody.trim().isNotEmpty) {
        try {
          body = jsonDecode(rawBody);
        } on FormatException {
          throw ApiException(
            'Backend returned non-JSON response. '
            'HTTP ${response.statusCode}, '
            'Content-Type: $contentType',
            statusCode: response.statusCode,
          );
        }
      }

      // Handle HTTP errors.
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Request failed';

        if (body is Map) {
          message = (body['message'] ?? body['error'] ?? message).toString();
        }

        throw ApiException(message, statusCode: response.statusCode);
      }

      if (body == null) {
        return <String, Object?>{};
      }

      if (body is Map) {
        return Map<String, Object?>.from(body);
      }

      throw ApiException(
        'API response must be a JSON object',
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Request timed out. Please check your connection.',
      );
    } on SocketException {
      throw const ApiException('Cannot connect to AssetOne Backend.');
    } on http.ClientException {
      throw const ApiException('HTTP client connection failed.');
    } on FormatException {
      throw const ApiException('Invalid JSON response from server.');
    }
  }

  @override
  Future<Map<String, Object?>> get(String path, {Map<String, String>? query}) {
    return _send(() => _client.get(_buildUri(path, query), headers: _headers));
  }

  @override
  Future<Map<String, Object?>> post(String path, {Map<String, Object?>? body}) {
    return _send(
      () => _client.post(
        _buildUri(path),
        headers: _headers,
        body: jsonEncode(body ?? const <String, Object?>{}),
      ),
    );
  }

  @override
  Future<Map<String, Object?>> patch(
    String path, {
    Map<String, Object?>? body,
  }) {
    return _send(
      () => _client.patch(
        _buildUri(path),
        headers: _headers,
        body: jsonEncode(body ?? const <String, Object?>{}),
      ),
    );
  }

  @override
  Future<Map<String, Object?>> delete(String path) {
    return _send(() => _client.delete(_buildUri(path), headers: _headers));
  }

  void close() {
    _client.close();
  }
}
