import '../../../../core/result/result.dart';
import '../entities/asset_summary.dart';
import '../repositories/assets_repository.dart';

final class GetAssets {
  const GetAssets(this._repository);

  final AssetsRepository _repository;

  Future<Result<List<AssetSummary>>> call() => _repository.getAssets();
}
