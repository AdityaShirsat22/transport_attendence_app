import 'package:flutter_test/flutter_test.dart';
import 'package:fleettrack/features/attendance/domain/attendance_record.dart';
import 'package:fleettrack/features/employees/domain/employee.dart';
import 'package:fleettrack/features/employees/domain/employee_enums.dart';
import 'package:fleettrack/features/settings/domain/company_settings.dart';

void main() {
  group('Data Models Tests', () {
    test('Employee serialization and legacy JSON compatibility', () {
      const emp = Employee(
        id: 'emp-drv-01',
        name: 'Rajesh Kumar Patil',
        type: EmployeeType.driver,
        vehicleName: 'Tata Signa 4825.T Heavy Truck (MH 12 QX 4521)',
        description: 'Long Haul Multi-Axle Container Driver',
        phone: '+91 98231 11201',
        salary: 34000,
        salaryType: SalaryType.monthly,
        joinedDate: '2024-03-15',
        active: true,
      );

      final legacyJson = emp.toLegacyJson();
      final fromLegacy = Employee.fromLegacyJson(legacyJson);

      expect(fromLegacy.id, emp.id);
      expect(fromLegacy.name, emp.name);
      expect(fromLegacy.type, EmployeeType.driver);
      expect(fromLegacy.vehicleName, emp.vehicleName);
      expect(fromLegacy.salary, 34000.0);
      expect(fromLegacy.salaryType, SalaryType.monthly);

      final supabaseJson = emp.toJson();
      final fromSupabase = Employee.fromJson(supabaseJson);
      expect(fromSupabase.id, emp.id);
      expect(fromSupabase.vehicleName, emp.vehicleName);
    });

    test('CompanySettings serialization and legacy JSON compatibility', () {
      const settings = CompanySettings(
        companyName: 'National Roadlines & Transport Co.',
        tagline: 'Fleet Logistics, Heavy Cargo & Transport Services',
        phone: '+91 98220 54321',
        city: 'Transport Nagar, Logistics Hub',
        currency: '₹',
        standardMonthDays: 30,
      );

      final legacyJson = settings.toLegacyJson();
      final fromLegacy = CompanySettings.fromLegacyJson(legacyJson);

      expect(fromLegacy.companyName, settings.companyName);
      expect(fromLegacy.currency, '₹');
      expect(fromLegacy.standardMonthDays, 30);
    });

    test('AttendanceRecord serialization', () {
      const record = AttendanceRecord(
        id: 'emp-drv-01_2026-09-28',
        employeeId: 'emp-drv-01',
        date: '2026-09-28',
        status: AttendanceStatus.present,
      );

      final json = record.toJson();
      final fromJson = AttendanceRecord.fromJson(json);

      expect(fromJson.id, record.id);
      expect(fromJson.employeeId, 'emp-drv-01');
      expect(fromJson.date, '2026-09-28');
      expect(fromJson.status, AttendanceStatus.present);
    });
  });
}
