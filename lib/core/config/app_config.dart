/// Public build configuration. Never put database credentials or secrets here.
final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.useDemoData,
    this.apiBaseUrl,
  });

  factory AppConfig.fromEnvironment() {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    return const AppConfig(
      environment: String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
      ),
      useDemoData: bool.fromEnvironment('USE_DEMO_DATA', defaultValue: true),
      apiBaseUrl: apiBaseUrl == '' ? null : apiBaseUrl,
    );
  }

  final String environment;
  final bool useDemoData;
  final String? apiBaseUrl;
}
