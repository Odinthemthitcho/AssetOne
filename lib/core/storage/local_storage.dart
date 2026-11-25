import 'storage_native.dart'
    if (dart.library.js_interop) 'storage_web.dart'
    as platform;

abstract interface class LocalStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

LocalStorage createLocalStorage() => platform.createStorage();

final class MemoryStorage implements LocalStorage {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
