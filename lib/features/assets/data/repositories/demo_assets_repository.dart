import '../../../../core/result/result.dart';
import '../../domain/entities/asset_summary.dart';
import '../../domain/repositories/assets_repository.dart';
import '../datasources/demo_assets_data_source.dart';

final class DemoAssetsRepository implements AssetsRepository {
  const DemoAssetsRepository([this._dataSource = const DemoAssetsDataSource()]);

  final DemoAssetsDataSource _dataSource;

  @override
  Future<Result<List<AssetSummary>>> getAssets() async {
    final models = await _dataSource.getAssets();
    return Success(List.unmodifiable(models.map((model) => model.toEntity())));
  }
}
