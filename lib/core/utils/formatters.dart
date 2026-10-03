import 'package:intl/intl.dart';

/// Date formatting and utility functions.
class AppDateUtils {
  AppDateUtils._();

  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _displayFormat = DateFormat('EEE, MMM d, yyyy');
  static final _monthYearFormat = DateFormat('MMMM yyyy');

  /// Format a DateTime to YYYY-MM-DD string.
  static String toDateKey(DateTime date) => _dateFormat.format(date);

  /// Parse a YYYY-MM-DD string to DateTime.
  static DateTime fromDateKey(String key) => _dateFormat.parse(key);

  /// Format for display (e.g., "Mon, Sep 28, 2026").
  static String formatDisplay(DateTime date) => _displayFormat.format(date);

  /// Format month and year (e.g., "September 2026").
  static String formatMonthYear(int year, int month) =>
      _monthYearFormat.format(DateTime(year, month));

  /// Get the number of days in a given month.
  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// Get today's date as YYYY-MM-DD string.
  static String todayKey() => toDateKey(DateTime.now());

  /// Get today's DateTime with time zeroed out.
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Get the month name for a 1-based month index.
  static String monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month - 1];
  }

  /// Build a date key from year, month, day.
  static String buildDateKey(int year, int month, int day) {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$year-$m-$d';
  }
}

/// Currency formatting utilities.
class CurrencyUtils {
  CurrencyUtils._();

  /// Format an amount with the given currency symbol using Indian numbering.
  static String format(num amount, [String currency = '₹']) {
    final formatter = NumberFormat.decimalPattern('en_IN');
    return '$currency ${formatter.format(amount)}';
  }
}
