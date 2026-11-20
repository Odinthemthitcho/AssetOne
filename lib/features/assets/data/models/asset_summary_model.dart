import '../../domain/entities/asset_summary.dart';

/// DTO contract proposed for an asset summary endpoint.
///
/// This is not a SQL-table serializer. The backend must calculate [value] and
/// return it as a decimal string in the requested currency.
final class AssetSummaryModel {
  const AssetSummaryModel({
    required this.id,
    required this.ownershipCategoryId,
    required this.name,
    required this.assetTypeCode,
    required this.currencyCode,
    required this.value,
    this.isDemo = false,
  });

  factory AssetSummaryModel.fromJson(Map<String, Object?> json) {
    final value = _requiredString(json, 'value');
    if (value != value.trim() || !_decimalPattern.hasMatch(value)) {
      throw const FormatException(
        'value must be a non-negative decimal string',
      );
    }
    final isDemo = json['is_demo'] ?? false;
    if (isDemo is! bool) {
      throw const FormatException('is_demo must be a boolean');
    }
    return AssetSummaryModel(
      id: _requiredString(json, 'id'),
      ownershipCategoryId: _requiredString(json, 'ownership_category_id'),
      name: _requiredString(json, 'name'),
      assetTypeCode: _requiredString(json, 'asset_type_code'),
      currencyCode: _requiredString(json, 'currency_code'),
      value: value,
      isDemo: isDemo,
    );
  }

  static final _decimalPattern = RegExp(r'^(0|[1-9]\d*)(\.\d+)?$');

  final String id;
  final String ownershipCategoryId;
  final String name;
  final String assetTypeCode;
  final String currencyCode;
  final String value;
  final bool isDemo;

  AssetSummary toEntity() => AssetSummary(
    id: id,
    ownershipCategoryId: ownershipCategoryId,
    name: name,
    assetTypeCode: assetTypeCode,
    currencyCode: currencyCode,
    value: value,
    isDemo: isDemo,
  );

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key must be a non-empty string');
    }
    return value;
  }
}
