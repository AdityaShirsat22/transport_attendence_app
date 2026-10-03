import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fleettrack/core/config/supabase_config.dart';
import 'package:fleettrack/features/employees/domain/employee.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> getEmployees();
  Future<void> addEmployee(Employee employee);
  Future<void> updateEmployee(Employee employee);
  Future<void> deleteEmployee(String id);
  Future<List<Employee>> resetToDefaults();
  Future<void> restoreEmployees(List<Employee> employees);
}

class SupabaseEmployeeRepository implements EmployeeRepository {
  List<Employee> _cachedEmployees = [];

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Employee>> getEmployees() async {
    final client = _client;
    if (!SupabaseConfig.isConfigured || client == null) {
      return List.unmodifiable(_cachedEmployees);
    }

    try {
      final response = await client
          .from('employees')
          .select()
          .order('name', ascending: true);

      final list = (response as List)
          .map((item) => Employee.fromJson(item as Map<String, dynamic>))
          .toList();

      _cachedEmployees = list;
      return List.unmodifiable(_cachedEmployees);
    } catch (e) {
      debugPrint('Failed to load employees from Supabase: $e');
      return List.unmodifiable(_cachedEmployees);
    }
  }

  @override
  Future<void> addEmployee(Employee employee) async {
    _cachedEmployees.insert(0, employee);

    final client = _client;
    if (SupabaseConfig.isConfigured && client != null) {
      try {
        await client.from('employees').insert(employee.toJson());
      } catch (e) {
        debugPrint('Failed to add employee in Supabase: $e');
        rethrow;
      }
    }
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    final index = _cachedEmployees.indexWhere((e) => e.id == employee.id);
    if (index >= 0) {
      _cachedEmployees[index] = employee;
    }

    final client = _client;
    if (SupabaseConfig.isConfigured && client != null) {
      try {
        await client
            .from('employees')
            .update(employee.toJson())
            .eq('id', employee.id);
      } catch (e) {
        debugPrint('Failed to update employee in Supabase: $e');
        rethrow;
      }
    }
  }

  @override
  Future<void> deleteEmployee(String id) async {
    _cachedEmployees.removeWhere((e) => e.id == id);

    final client = _client;
    if (SupabaseConfig.isConfigured && client != null) {
      try {
        await client.from('employees').delete().eq('id', id);
      } catch (e) {
        debugPrint('Failed to delete employee in Supabase: $e');
        rethrow;
      }
    }
  }

  @override
  Future<List<Employee>> resetToDefaults() async {
    _cachedEmployees = [];

    final client = _client;
    if (SupabaseConfig.isConfigured && client != null) {
      try {
        await client.from('employees').delete().neq('id', '');
      } catch (e) {
        debugPrint('Failed to clear employees in Supabase: $e');
      }
    }

    return List.unmodifiable(_cachedEmployees);
  }

  @override
  Future<void> restoreEmployees(List<Employee> employees) async {
    _cachedEmployees = List.from(employees);

    final client = _client;
    if (SupabaseConfig.isConfigured && client != null) {
      try {
        await client.from('employees').delete().neq('id', '');
        for (final emp in employees) {
          await client.from('employees').upsert(emp.toJson());
        }
      } catch (e) {
        debugPrint('Failed to restore employees in Supabase: $e');
        rethrow;
      }
    }
  }
}
