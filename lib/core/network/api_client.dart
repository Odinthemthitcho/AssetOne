/// Contract for the future HTTPS adapter.
///
/// Implement authentication, status/error mapping, cancellation and timeouts
/// in an adapter. Financial decimals must arrive as JSON strings. The Flutter
/// app talks to a backend; it does not connect directly to SQL Server.
abstract interface class ApiClient {
  Future<Map<String, Object?>> get(String path, {Map<String, String>? query});

  Future<Map<String, Object?>> post(String path, {Map<String, Object?>? body});

  Future<Map<String, Object?>> patch(String path, {Map<String, Object?>? body});

  Future<Map<String, Object?>> delete(String path);
}
