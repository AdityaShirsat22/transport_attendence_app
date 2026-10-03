import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleettrack/features/employees/data/employee_repository.dart';
import 'package:fleettrack/features/employees/domain/employee.dart';
import 'package:fleettrack/features/employees/domain/employee_enums.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return SupabaseEmployeeRepository();
});

class EmployeesNotifier extends StateNotifier<AsyncValue<List<Employee>>> {
  final EmployeeRepository _repository;

  EmployeesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadEmployees();
  }

  Future<void> loadEmployees() async {
    try {
      final list = await _repository.getEmployees();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveEmployee(Employee employee) async {
    final currentList = state.value ?? [];
    final existsIndex = currentList.indexWhere((e) => e.id == employee.id);

    List<Employee> updatedList;
    if (existsIndex >= 0) {
      updatedList = List.from(currentList)..[existsIndex] = employee;
      state = AsyncValue.data(updatedList);
      await _repository.updateEmployee(employee);
    } else {
      updatedList = [employee, ...currentList];
      state = AsyncValue.data(updatedList);
      await _repository.addEmployee(employee);
    }
  }

  Future<void> deleteEmployee(String id) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.where((e) => e.id != id).toList();
    state = AsyncValue.data(updatedList);
    await _repository.deleteEmployee(id);
  }

  Future<void> resetToDefaults() async {
    final list = await _repository.resetToDefaults();
    state = AsyncValue.data(list);
  }

  Future<void> restoreEmployees(List<Employee> employees) async {
    state = AsyncValue.data(employees);
    await _repository.restoreEmployees(employees);
  }
}

final employeesProvider =
    StateNotifierProvider<EmployeesNotifier, AsyncValue<List<Employee>>>((ref) {
  final repo = ref.watch(employeeRepositoryProvider);
  return EmployeesNotifier(repo);
});

/// Filtered drivers provider
final driversProvider = Provider<List<Employee>>((ref) {
  final employeesAsync = ref.watch(employeesProvider);
  return employeesAsync.maybeWhen(
    data: (list) => list.where((e) => e.type == EmployeeType.driver).toList(),
    orElse: () => [],
  );
});

/// Filtered staff provider
final staffProvider = Provider<List<Employee>>((ref) {
  final employeesAsync = ref.watch(employeesProvider);
  return employeesAsync.maybeWhen(
    data: (list) => list.where((e) => e.type == EmployeeType.staff).toList(),
    orElse: () => [],
  );
});

/// Active workforce count provider
final activeEmployeesCountProvider = Provider<int>((ref) {
  final employeesAsync = ref.watch(employeesProvider);
  return employeesAsync.maybeWhen(
    data: (list) => list.where((e) => e.active).length,
    orElse: () => 0,
  );
});
