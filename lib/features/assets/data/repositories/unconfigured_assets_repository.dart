import '../../../../core/error/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/asset_summary.dart';
import '../../domain/repositories/assets_repository.dart';

/// Explicitly reports the missing backend instead of showing demo data as real.
final class UnconfiguredAssetsRepository implements AssetsRepository {
  const UnconfiguredAssetsRepository();

  @override
  Future<Result<List<AssetSummary>>> getAssets() async => const Failure(
    AppFailure(
      'Chưa kết nối API tài sản. Hãy triển khai nguồn dữ liệu và repository API '
      'trước khi sử dụng dữ liệu thật.',
      code: 'assets_api_not_configured',
    ),
  );
}
