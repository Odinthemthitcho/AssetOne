import '../models/asset_summary_model.dart';

/// Local, deterministic demonstration data. Never represents a user's holdings.
final class DemoAssetsDataSource {
  const DemoAssetsDataSource();

  Future<List<AssetSummaryModel>> getAssets() async =>
      List.unmodifiable(_rows.map(AssetSummaryModel.fromJson));

  static const _rows = <Map<String, Object?>>[
    {
      'id': 'demo-deposit',
      'ownership_category_id': 'demo-owner',
      'name': 'Tiền gửi minh họa',
      'asset_type_code': 'BANK_DEPOSIT',
      'currency_code': 'VND',
      'value': '100000000.0000000000',
      'is_demo': true,
    },
    {
      'id': 'demo-equity',
      'ownership_category_id': 'demo-owner',
      'name': 'Danh mục cổ phiếu minh họa',
      'asset_type_code': 'EQUITY',
      'currency_code': 'VND',
      'value': '25000000.0000000000',
      'is_demo': true,
    },
    {
      'id': 'demo-foreign-currency',
      'ownership_category_id': 'demo-owner',
      'name': 'Ngoại tệ minh họa',
      'asset_type_code': 'FOREIGN_CURRENCY',
      'currency_code': 'USD',
      'value': '1500.2500000000',
      'is_demo': true,
    },
  ];
}
