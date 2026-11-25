/// Exact decimal transport value, with no conversion to binary floating point.
///
/// Canonicalizes leading/trailing zeros and negative zero. This type deliberately
/// does not perform arithmetic or impose a database precision/scale. A future
/// decimal arithmetic adapter must apply the backend's rounding policy.
final class DecimalValue {
  const DecimalValue._(this.value);

  factory DecimalValue.parse(String source) {
    final input = source.trim();
    if (!_pattern.hasMatch(input)) {
      throw FormatException('Expected a plain decimal string', source);
    }

    final isNegative = input.startsWith('-');
    final unsigned = input.startsWith('-') || input.startsWith('+')
        ? input.substring(1)
        : input;
    final parts = unsigned.split('.');
    var whole = parts.first.replaceFirst(RegExp(r'^0+'), '');
    if (whole.isEmpty) whole = '0';
    final fraction = parts.length == 2
        ? parts[1].replaceFirst(RegExp(r'0+$'), '')
        : '';
    final magnitude = fraction.isEmpty ? whole : '$whole.$fraction';
    return DecimalValue._(
      isNegative && magnitude != '0' ? '-$magnitude' : magnitude,
    );
  }

  static final RegExp _pattern = RegExp(r'^[+-]?[0-9]+(?:\.[0-9]+)?$');

  static DecimalValue? tryParse(String source) {
    try {
      return DecimalValue.parse(source);
    } on FormatException {
      return null;
    }
  }

  /// Canonical decimal string for JSON/API serialization.
  final String value;

  bool get isNegative => value.startsWith('-');
  bool get isZero => value == '0';

  @override
  bool operator ==(Object other) =>
      other is DecimalValue && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
