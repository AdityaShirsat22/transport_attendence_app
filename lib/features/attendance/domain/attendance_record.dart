import 'package:fleettrack/features/employees/domain/employee_enums.dart';

/// A single attendance record row in the database.
class AttendanceRecord {
  final String id;
  final String employeeId;
  final String date; // YYYY-MM-DD
  final AttendanceStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'] as String,
        employeeId: json['employee_id'] as String,
        date: json['date'] as String,
        status: AttendanceStatus.fromString(json['status'] as String),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_id': employeeId,
    'date': date,
    'status': status.name,
  };

  AttendanceRecord copyWith({
    String? id,
    String? employeeId,
    String? date,
    AttendanceStatus? status,
  }) =>
      AttendanceRecord(
        id: id ?? this.id,
        employeeId: employeeId ?? this.employeeId,
        date: date ?? this.date,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

/// In-memory attendance map for a single date.
/// Maps employeeId -> AttendanceStatus.
typedef DailyAttendanceMap = Map<String, AttendanceStatus>;

/// In-memory attendance map for a month.
/// Maps dateKey (YYYY-MM-DD) -> { employeeId: AttendanceStatus }.
typedef MonthlyAttendanceMap = Map<String, DailyAttendanceMap>;
