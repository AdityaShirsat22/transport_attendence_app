import 'package:flutter_test/flutter_test.dart';
import 'package:fleettrack/core/utils/salary_calculator.dart';

void main() {
  group('SalaryCalculator Tests', () {
    test('Calculates monthly salary with standard 30-day divisor', () {
      // e.g. Rajesh Kumar Patil: 34000 salary, monthly, 25 present days, standard 30 days
      final stats = SalaryCalculator.calculate(
        salary: 34000,
        salaryType: 'monthly',
        presentDays: 25,
        absentDays: 3,
        year: 2026,
        month: 9, // September (30 days)
        standardMonthDays: 30,
      );

      // dailyRate = round((34000 / 30) * 100) / 100 = 1133.33
      // payable = round(1133.33 * 25) = 28333
      expect(stats.totalDays, 30);
      expect(stats.presentDays, 25);
      expect(stats.absentDays, 3);
      expect(stats.dailyRate, 1133.33);
      expect(stats.payableSalary, 28333.0);
    });

    test('Calculates daily wage salary correctly', () {
      // e.g. 1200 per day wage, 20 present days
      final stats = SalaryCalculator.calculate(
        salary: 1200,
        salaryType: 'daily',
        presentDays: 20,
        absentDays: 5,
        year: 2026,
        month: 9,
        standardMonthDays: 30,
      );

      expect(stats.dailyRate, 1200.0);
      expect(stats.payableSalary, 24000.0);
    });

    test('Zero present days results in zero payable salary', () {
      final stats = SalaryCalculator.calculate(
        salary: 30000,
        salaryType: 'monthly',
        presentDays: 0,
        absentDays: 10,
        year: 2026,
        month: 9,
        standardMonthDays: 30,
      );

      expect(stats.payableSalary, 0.0);
    });

    test('Calendar days used when standardMonthDays is 0', () {
      // February in leap year 2024 = 29 days
      final stats = SalaryCalculator.calculate(
        salary: 29000,
        salaryType: 'monthly',
        presentDays: 29,
        absentDays: 0,
        year: 2024,
        month: 2,
        standardMonthDays: 0,
      );

      expect(stats.totalDays, 29);
      expect(stats.dailyRate, 1000.0);
      expect(stats.payableSalary, 29000.0);
    });
  });
}
