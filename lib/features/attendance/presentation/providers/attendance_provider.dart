import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleettrack/features/attendance/data/attendance_repository.dart';
import 'package:fleettrack/features/attendance/domain/attendance_record.dart';
import 'package:fleettrack/features/employees/domain/employee_enums.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return SupabaseAttendanceRepository();
});

class AttendanceNotifier extends StateNotifier<AsyncValue<MonthlyAttendanceMap>> {
  final AttendanceRepository _repository;

  AttendanceNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadAttendance();
  }

  Future<void> loadAttendance() async {
    try {
      final map = await _repository.getAttendance();
      state = AsyncValue.data(map);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Mark single employee on dateKey. If clicking existing status, unmark (toggle behavior).
  Future<void> markAttendance(
    String dateKey,
    String employeeId,
    AttendanceStatus status,
  ) async {
    final currentMap = state.value ?? {};
    final updatedMap = Map<String, DailyAttendanceMap>.from(currentMap);
    final dayRecord = Map<String, AttendanceStatus>.from(updatedMap[dateKey] ?? {});

    AttendanceStatus? targetStatus;
    if (dayRecord[employeeId] == status) {
      // Toggle off
      dayRecord.remove(employeeId);
      targetStatus = null;
    } else {
      dayRecord[employeeId] = status;
      targetStatus = status;
    }

    updatedMap[dateKey] = dayRecord;
    state = AsyncValue.data(updatedMap);
    await _repository.markAttendance(dateKey, employeeId, targetStatus);
  }

  /// Batch mark a list of employees (e.g. Mark All Present or Absent)
  Future<void> batchMark(
    String dateKey,
    List<String> employeeIds,
    AttendanceStatus status,
  ) async {
    final currentMap = state.value ?? {};
    final updatedMap = Map<String, DailyAttendanceMap>.from(currentMap);
    final dayRecord = Map<String, AttendanceStatus>.from(updatedMap[dateKey] ?? {});

    for (final id in employeeIds) {
      dayRecord[id] = status;
    }

    updatedMap[dateKey] = dayRecord;
    state = AsyncValue.data(updatedMap);
    await _repository.batchMark(dateKey, employeeIds, status);
  }

  /// Clear all marks for a date
  Future<void> clearDate(String dateKey) async {
    final currentMap = state.value ?? {};
    final updatedMap = Map<String, DailyAttendanceMap>.from(currentMap);
    updatedMap.remove(dateKey);

    state = AsyncValue.data(updatedMap);
    await _repository.clearDate(dateKey);
  }

  /// Toggle cell in monthly register matrix (unmarked -> present -> absent -> unmarked)
  Future<void> toggleCellAttendance(String dateKey, String employeeId) async {
    final currentMap = state.value ?? {};
    final updatedMap = Map<String, DailyAttendanceMap>.from(currentMap);
    final dayRecord = Map<String, AttendanceStatus>.from(updatedMap[dateKey] ?? {});

    final current = dayRecord[employeeId];
    AttendanceStatus? targetStatus;

    if (current == null) {
      dayRecord[employeeId] = AttendanceStatus.present;
      targetStatus = AttendanceStatus.present;
    } else if (current == AttendanceStatus.present) {
      dayRecord[employeeId] = AttendanceStatus.absent;
      targetStatus = AttendanceStatus.absent;
    } else {
      dayRecord.remove(employeeId);
      targetStatus = null;
    }

    updatedMap[dateKey] = dayRecord;
    state = AsyncValue.data(updatedMap);
    await _repository.markAttendance(dateKey, employeeId, targetStatus);
  }

  Future<void> resetToDefaults() async {
    final map = await _repository.resetToDefaults();
    state = AsyncValue.data(map);
  }

  Future<void> restoreAttendance(MonthlyAttendanceMap data) async {
    state = AsyncValue.data(data);
    await _repository.restoreAttendance(data);
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AsyncValue<MonthlyAttendanceMap>>((ref) {
  final repo = ref.watch(attendanceRepositoryProvider);
  return AttendanceNotifier(repo);
});
