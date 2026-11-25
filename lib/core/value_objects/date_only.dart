/// Calendar date for SQL `date` fields. It has no time or timezone conversion.
final class DateOnly implements Comparable<DateOnly> {
  factory DateOnly(int year, int month, int day) {
    if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1) {
      throw ArgumentError('Invalid calendar date: $year-$month-$day');
    }
    final date = DateTime.utc(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      throw ArgumentError('Invalid calendar date: $year-$month-$day');
    }
    return DateOnly._(year, month, day);
  }

  const DateOnly._(this.year, this.month, this.day);

  factory DateOnly.parse(String source) {
    final match = _pattern.firstMatch(source);
    if (match == null) {
      throw FormatException('Expected YYYY-MM-DD', source);
    }
    try {
      return DateOnly(
        int.parse(match[1]!),
        int.parse(match[2]!),
        int.parse(match[3]!),
      );
    } on ArgumentError {
      throw FormatException('Invalid calendar date', source);
    }
  }

  static final RegExp _pattern = RegExp(r'^([0-9]{4})-([0-9]{2})-([0-9]{2})$');

  static DateOnly? tryParse(String source) {
    try {
      return DateOnly.parse(source);
    } on FormatException {
      return null;
    }
  }

  final int year;
  final int month;
  final int day;

  @override
  int compareTo(DateOnly other) {
    final yearComparison = year.compareTo(other.year);
    if (yearComparison != 0) return yearComparison;
    final monthComparison = month.compareTo(other.month);
    return monthComparison != 0 ? monthComparison : day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is DateOnly &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
