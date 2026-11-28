
import '../../core/config/app_config.dart';
import '../../core/storage/local_storage.dart';
import '../../core/storage/secure_token_storage.dart';
import '../../core/network/api_client.dart';
import '../../core/network/http_api_client.dart';

import '../../features/auth/data/api_auth.dart';
import '../../features/assets/data/repositories/demo_assets_repository.dart';
import '../../features/assets/data/repositories/unconfigured_assets_repository.dart';
import '../../features/assets/domain/repositories/assets_repository.dart';
import '../../features/assets/domain/usecases/get_assets.dart';
import '../../features/assets/presentation/controllers/assets_controller.dart';
import '../../features/portfolio/data/portfolio_store.dart';

/// Composition root: choose implementations outside widgets and domain.
final class AppDependencies {
  AppDependencies(this.config, {LocalStorage? storage})
      : storage = storage ?? createLocalStorage();

  final AppConfig config;
  final LocalStorage storage;

  // Secure storage for JWT.
  late final SecureTokenStorage tokenStorage = SecureTokenStorage();

  // Authentication through Node.js Backend.
  late final ApiAuth auth = ApiAuth(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
    profileStorage: storage,
  );

  // Portfolio - existing implementation.
  late final PortfolioStore portfolio = PortfolioStore(storage);

  // HTTP API - shared Backend connection.
  late final HttpApiClient _httpApiClient = HttpApiClient();

  ApiClient get apiClient => _httpApiClient;

  // Check Node.js Backend.
  Future<Map<String, Object?>> checkBackend() {
    return apiClient.get('/api/health');
  }

  // Check SQL Server through Node.js Backend.
  Future<Map<String, Object?>> checkDatabase() {
    return apiClient.get('/api/test-db');
  }

  // Existing Assets configuration - preserve current behavior.
  late final AssetsRepository assetsRepository = config.useDemoData
      ? DemoAssetsRepository()
      : UnconfiguredAssetsRepository();

  AssetsController createAssetsController() =>
      AssetsController(GetAssets(assetsRepository));

  void dispose() {
    _httpApiClient.close();
  }
}
