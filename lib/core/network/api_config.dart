class ApiConfig {
  ApiConfig._();

  // Android Emulator truy cập Backend trên máy tính
  static const String baseUrl = String.fromEnvironment(
    'ASSETONE_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const Duration connectTimeout = Duration(seconds: 10);

  static const Duration receiveTimeout = Duration(seconds: 15);
}
