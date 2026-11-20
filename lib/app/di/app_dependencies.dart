import '../../core/config/app_config.dart';
import '../../core/storage/local_storage.dart';
import '../../features/auth/data/local_auth.dart';
import '../../features/assets/data/repositories/demo_assets_repository.dart';
import '../../features/assets/data/repositories/unconfigured_assets_repository.dart';
import '../../features/assets/domain/repositories/assets_repository.dart';
import '../../features/assets/domain/usecases/get_assets.dart';
import '../../features/assets/presentation/controllers/assets_controller.dart';
import '../../features/portfolio/data/portfolio_store.dart';

/// Choose implementations here, outside widgets and domain.
final class AppDependencies {
  AppDependencies(this.config, {LocalStorage? storage})
    : storage = storage ?? createLocalStorage();

  final AppConfig config;
  final LocalStorage storage;
  late final LocalAuth auth = LocalAuth(storage);
  late final PortfolioStore portfolio = PortfolioStore(storage);

  late final AssetsRepository assetsRepository = config.useDemoData
      ? DemoAssetsRepository()
      : UnconfiguredAssetsRepository();

  AssetsController createAssetsController() =>
      AssetsController(GetAssets(assetsRepository));
}
