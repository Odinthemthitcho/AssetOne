import '../../../core/value_objects/decimal_value.dart';

abstract final class PortfolioAmounts {
  /// Limits integer VND values to amounts representable exactly on web/mobile.
  static const maxVnd = 9007199254740991;

  static int? parseVnd(String source) {
    var value = _withoutSpaces(source);
    if (_groupedInteger.hasMatch(value)) {
      value = value.replaceAll('.', '');
    }
    if (!_plainInteger.hasMatch(value)) return null;
    final amount = int.tryParse(value);
    if (amount == null || amount < -maxVnd || amount > maxVnd) return null;
    return amount;
  }

  static String? parseDecimal(String source) {
    var value = _withoutSpaces(source);
    if (value.contains(',')) {
      final parts = value.split(',');
      if (parts.length != 2) return null;
      final whole = parts.first;
      if (!_groupedInteger.hasMatch(whole) && !_plainInteger.hasMatch(whole)) {
        return null;
      }
      value = '${whole.replaceAll('.', '')}.${parts.last}';
    } else if ('.'.allMatches(value).length > 1 &&
        _groupedInteger.hasMatch(value)) {
      value = value.replaceAll('.', '');
    }
    final canonical = DecimalValue.tryParse(value)?.value;
    if (canonical == null) return null;
    final parts = canonical.split('.');
    if (parts.first.replaceFirst('-', '').length > 16 ||
        (parts.length == 2 && parts.last.length > 18)) {
      return null;
    }
    return canonical;
  }

  static int product(
    String quantity,
    String unitPrice, [
    String? conversionRate,
  ]) {
    final qty = parseDecimal(quantity);
    final price = parseDecimal(unitPrice);
    final rate = parseDecimal(conversionRate ?? '1');
    if (qty == null || price == null || rate == null) {
      throw const FormatException('Số lượng hoặc đơn giá chưa hợp lệ.');
    }
    return PortfolioDecimal.parse(
      qty,
    ).times(PortfolioDecimal.parse(price), PortfolioDecimal.parse(rate));
  }

  /// Simple annual interest using a fixed 365-day basis and VND rounding.
  static int simpleInterest(int principal, String annualRate, int days) {
    final rate = parseDecimal(annualRate);
    if (rate == null || rate.startsWith('-') || days < 0 || principal < 0) {
      throw const FormatException('Gốc, lãi suất hoặc kỳ hạn chưa hợp lệ.');
    }
    return PortfolioDecimal.parse(
      rate,
    ).portionOf(principal, PortfolioDecimal.parse('36500'), days: days);
  }

  static int ownedShare(int fullAmount, String percent) {
    final canonical = parseDecimal(percent);
    if (canonical == null || fullAmount < 0 || fullAmount > maxVnd) {
      throw const FormatException('Giá trị hoặc tỷ lệ sở hữu chưa hợp lệ.');
    }
    final ownership = PortfolioDecimal.parse(canonical);
    final whole = PortfolioDecimal.parse('100');
    if (!ownership.isPositive || ownership.compareTo(whole) > 0) {
      throw const FormatException(
        'Tỷ lệ sở hữu phải lớn hơn 0% và tối đa 100%.',
      );
    }
    return ownership.portionOf(fullAmount, whole);
  }

  static String formatVnd(int amount) => '${formatInteger(amount)} ₫';

  static String formatInteger(int amount) {
    final digits = amount.abs().toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return amount < 0 ? '-$grouped' : grouped;
  }

  static int roundedVnd(BigInt numerator, BigInt denominator) {
    final magnitude = numerator.abs();
    var rounded = magnitude ~/ denominator;
    if ((magnitude % denominator) * BigInt.two >= denominator) {
      rounded += BigInt.one;
    }
    final signed = numerator.isNegative ? -rounded : rounded;
    if (signed.abs() > BigInt.from(maxVnd)) {
      throw const FormatException('Số tiền vượt giới hạn ghi nhận.');
    }
    return signed.toInt();
  }

  static String _withoutSpaces(String source) =>
      source.trim().replaceAll(RegExp('[\u00a0\u202f ]'), '');

  static final _plainInteger = RegExp(r'^[+-]?\d+$');
  static final _groupedInteger = RegExp(r'^[+-]?\d{1,3}(?:\.\d{3})+$');
}

/// Fixed-scale units used for exact quantity and weighted-average cost arithmetic.
final class PortfolioDecimal implements Comparable<PortfolioDecimal> {
  PortfolioDecimal._(this._units);

  factory PortfolioDecimal.parse(String canonical) {
    final negative = canonical.startsWith('-');
    final parts = (negative ? canonical.substring(1) : canonical).split('.');
    final fraction = parts.length == 2 ? parts[1] : '';
    final units = BigInt.parse(
      '${parts.first}${fraction.padRight(_scale, '0')}',
    );
    return PortfolioDecimal._(negative ? -units : units);
  }

  static const _scale = 18;
  static final _unit = BigInt.from(10).pow(_scale);
  final BigInt _units;

  bool get isPositive => _units > BigInt.zero;
  bool get isZero => _units == BigInt.zero;

  PortfolioDecimal operator +(PortfolioDecimal other) =>
      PortfolioDecimal._(_units + other._units);

  PortfolioDecimal operator -(PortfolioDecimal other) =>
      PortfolioDecimal._(_units - other._units);

  int times(PortfolioDecimal other, [PortfolioDecimal? factor]) {
    var numerator = _units * other._units;
    var denominator = _unit * _unit;
    if (factor != null) {
      numerator *= factor._units;
      denominator *= _unit;
    }
    return PortfolioAmounts.roundedVnd(numerator, denominator);
  }

  int portionOf(int amount, PortfolioDecimal total, {int days = 1}) =>
      PortfolioAmounts.roundedVnd(
        _units * BigInt.from(amount) * BigInt.from(days),
        total._units,
      );

  @override
  int compareTo(PortfolioDecimal other) => _units.compareTo(other._units);

  @override
  String toString() {
    final digits = _units.abs().toString().padLeft(_scale + 1, '0');
    final boundary = digits.length - _scale;
    final fraction = digits
        .substring(boundary)
        .replaceFirst(RegExp(r'0+$'), '');
    final whole = digits.substring(0, boundary);
    final signed = _units.isNegative ? '-$whole' : whole;
    return fraction.isEmpty ? signed : '$signed.$fraction';
  }
}
