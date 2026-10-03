import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fleettrack/core/config/supabase_config.dart';
import 'package:fleettrack/features/employees/domain/employee_enums.dart';
import 'package:fleettrack/features/attendance/domain/attendance_record.dart';

abstract class AttendanceRepository {
  Future<MonthlyAttendanceMap> getAttendance();
  Future<void> markAttendance(
    String dateKey,
    String employeeId,
    AttendanceStatus? status,
  );
  Future<void> batchMark(
    String dateKey,
    List<String> employeeIds,
    AttendanceStatus status,
  );
  Future<void> clearDate(String dateKey);
  Future<MonthlyAttendanceMap> resetToDefaults();
  Future<void> restoreAttendance(MonthlyAttendanceMap data);
}

class SupabaseAttendanceRepository implements AttendanceRepository {
  MonthlyAttendanceMap _cachedAttendance = {};

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MonthlyAttendanceMap> getAttendance() async {
    final client = _client;
    if (!SupabaseConfig.isConfigured || client == null) {
      return Map.from(_cachedAttendance);
    }

    try {
      final response = await client
          .from('attendance_records')
          .select('employee_id, date, status');

      final list = response as List;
      final MonthlyAttendanceMap map = {};

      for (final item in list) {
        final dateKey = item['date'] as String;
        final empId = item['employee_id'] as String;
        final statusStr = item['status'] as String;
        final status = AttendanceStatus.fromString(statusStr);

        map.putIfAbsent(dateKey, () => {})[empId] = status;
      }

      _cachedAttendance = map;
      return Map.from(_cachedAttendance);
    } catch (e) {
      debugPrint('Failed to load attendance from Supabase: $e');
      return Map.from(_cachedAttendance);
    }
  }

  @override
  Future<void> markAttendance(
    String dateKey,
    String employeeId,
    AttendanceStatus? status,
  ) async {
    final dayMap = _cachedAttendance.putIfAbsent(dateKey, () => {});
    if (status == null) {
      dayMap.remove(employeeId);
    } else {
      dayMap[employeeId] = status;
    }

    final client = _client;
    if (SupabaseConfig.isConfigured && client != null) {
      try {
        final id = '${employeeId}_$dateKey';
        if (status == null) {
          await client
              .from('attendance_records')
              .delete()
              .eq('id', id);
        } else {
          await client
              .from('attendance_records')
              .upsert({
                'id': id,
                'employee_id': employeeId,
                'date': dateKey,
                'status': status.name,
              });
        }
      } catch (e) {
        debugPrint('Failed to sync attendance to Supabase: $e');
        rethrow;
      }
    }
  }

  @override
  Future<void> batchMark(
    String dateKey,
    List<String> employeeIds,
    AttendanceStatus status,
  ) async {
    final dayMap = _cachedAttendance.putIfAbsent(dateKey, () => {});
    final List<Map<String, dynamic>> recordsToUpsert = [];

    for (final empId in employeeIds) {
      dayMap[empId] = status;
      recordsToUpsert.add({
        'id': '${empId}_$dateKey',
        'employee_id': empId,
        'date': dateKey,
        'status': status.name,
      });
    }

    final client = _client;
    if (SupabaseConfig.isConfigured && client != null && recordsToUpsert.isNotEmpty) {
      try {
        await client
            .from('attendance_records')
            .upsert(recordsToUpsert);
      } catch (e) {
        debugPrint('Failed to batch mark attendance in Supabase: $e');
        rethrow;
      }
    }
  }

  @override
  Future<void> clearDate(String dateKey) async {
    _cachedAttendance.remove(dateKey);

    final client = _client;
    if (SupabaseConfig.isConfigured && client != null) {
      try {
        await client
            .from('attendance_records')
            .delete()
            .eq('date', dateKey);
      } catch (e) {
        debugPrint('Failed to clear date in Supabase: $e');
        rethrow;
      }
    }
  }

  @override
  Future<MonthlyAttendanceMap> resetToDefaults() async {
    _cachedAttendance = {};

    final client = _client;
    if (SupabaseConfig.isConfigured && client != null) {
      try {
        await client
            .from('attendance_records')
            .delete()
            .neq('id', '');
      } catch (e) {
        debugPrint('Failed to clear attendance in Supabase: $e');
      }
    }

    return Map.from(_cachedAttendance);
  }

  @override
  Future<void> restoreAttendance(MonthlyAttendanceMap data) async {
    _cachedAttendance = Map.from(data);

    final client = _client;
    if (SupabaseConfig.isConfigured && client != null) {
      try {
        await client
            .from('attendance_records')
            .delete()
            .neq('id', '');

        final List<Map<String, dynamic>> records = [];
        for (final entry in data.entries) {
          for (final empEntry in entry.value.entries) {
            records.add({
              'id': '${empEntry.key}_${entry.key}',
              'employee_id': empEntry.key,
              'date': entry.key,
              'status': empEntry.value.name,
            });
          }
        }
        if (records.isNotEmpty) {
          await client
              .from('attendance_records')
              .upsert(records);
        }
      } catch (e) {
        debugPrint('Failed to restore attendance in Supabase: $e');
        rethrow;
      }
    }
  }
}
