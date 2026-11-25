import '../../../../core/result/result.dart';
import '../entities/asset_summary.dart';

abstract interface class AssetsRepository {
  Future<Result<List<AssetSummary>>> getAssets();
}
