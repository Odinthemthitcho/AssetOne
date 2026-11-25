/// Public asset summary returned by the API, rather than a complete SQL row.
///
/// [value] remains a decimal string so serialization never rounds money through
/// a binary floating-point value. Portfolio calculations belong to the backend.
final class AssetSummary {
  const AssetSummary({
    required this.id,
    required this.ownershipCategoryId,
    required this.name,
    required this.assetTypeCode,
    required this.currencyCode,
    required this.value,
    this.isDemo = false,
  });

  final String id;
  final String ownershipCategoryId;
  final String name;
  final String assetTypeCode;
  final String currencyCode;
  final String value;
  final bool isDemo;
}
