import 'package:flutter_riverpod/flutter_riverpod.dart';

String _getTodayKey() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Currently selected date for Daily Attendance view (YYYY-MM-DD). Defaults to today.
final selectedDateProvider = StateProvider<String>((ref) => _getTodayKey());

/// Currently selected year for Monthly Register and Payroll views.
final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);

/// Currently selected month (1-12) for Monthly Register and Payroll views.
final selectedMonthProvider = StateProvider<int>((ref) => DateTime.now().month);

/// Bottom navigation tab index (0: Daily, 1: Monthly, 2: Payroll, 3: Drivers, 4: Staff).
final navigationIndexProvider = StateProvider<int>((ref) => 0);
