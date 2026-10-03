/// Salary calculation logic ported exactly from the original TypeScript source.
/// See: src/utils/salary.ts
class SalaryCalculator {
  SalaryCalculator._();

  /// Calculate monthly salary statistics for an employee.
  ///
  /// For monthly salary:
  ///   dailyRate = round((salary / divisor) * 100) / 100
  ///   payableSalary = round(dailyRate * presentDays)
  ///
  /// For daily salary:
  ///   dailyRate = salary
  ///   payableSalary = round(salary * presentDays)
  ///
  /// The divisor is settings.standardMonthDays if > 0, else daysInMonth.
  static MonthlyStats calculate({
    required double salary,
    required String salaryType,
    required int presentDays,
    required int absentDays,
    required int year,
    required int month,
    required int standardMonthDays,
  }) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final divisor = standardMonthDays > 0 ? standardMonthDays : daysInMonth;

    double dailyRate = 0;
    double payableSalary = 0;

    if (salaryType == 'daily') {
      dailyRate = salary;
      payableSalary = (salary * presentDays).roundToDouble();
    } else {
      // monthly salary
      dailyRate = ((salary / divisor) * 100).roundToDouble() / 100;
      payableSalary = (dailyRate * presentDays).roundToDouble();
    }

    return MonthlyStats(
      totalDays: daysInMonth,
      markedDays: presentDays + absentDays,
      presentDays: presentDays,
      absentDays: absentDays,
      dailyRate: dailyRate,
      baseSalary: salary,
      payableSalary: payableSalary,
    );
  }
}

/// Monthly salary calculation result.
class MonthlyStats {
  final int totalDays;
  final int markedDays;
  final int presentDays;
  final int absentDays;
  final double dailyRate;
  final double baseSalary;
  final double payableSalary;

  const MonthlyStats({
    required this.totalDays,
    required this.markedDays,
    required this.presentDays,
    required this.absentDays,
    required this.dailyRate,
    required this.baseSalary,
    required this.payableSalary,
  });
}
