import 'package:intl/intl.dart';

/// Dates are stored in SQLite as plain `yyyy-MM-dd` strings. This keeps range
/// queries ("all entries in November") simple string comparisons and avoids
/// timezone surprises for a date-only ledger.
class DateUtil {
  DateUtil._();

  static final DateFormat _ymd = DateFormat('yyyy-MM-dd');
  static final DateFormat _pretty = DateFormat('d MMM yyyy');
  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');

  /// A date with the time component stripped.
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime today() => dateOnly(DateTime.now());

  static String toKey(DateTime d) => _ymd.format(d);

  static DateTime fromKey(String key) => _ymd.parseStrict(key);

  static String pretty(DateTime d) => _pretty.format(d);

  static String dayMonth(DateTime d) => _dayMonth.format(d);

  static String monthYear(DateTime d) => _monthYear.format(d);

  /// First day of the month that [d] falls in.
  static DateTime firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  /// Last day of the month that [d] falls in.
  static DateTime lastOfMonth(DateTime d) => DateTime(d.year, d.month + 1, 0);

  /// Human ordinal day list, e.g. [6, 7, 19] -> "6th, 7th, 19th".
  static String ordinalDays(Iterable<int> days) =>
      days.map(ordinal).join(', ');

  static String ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}
