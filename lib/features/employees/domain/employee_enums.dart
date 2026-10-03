/// Employee type classification.
enum EmployeeType {
  driver,
  staff;

  String get label => switch (this) {
    EmployeeType.driver => 'Driver',
    EmployeeType.staff => 'Staff',
  };

  static EmployeeType fromString(String value) => switch (value) {
    'driver' => EmployeeType.driver,
    'staff' => EmployeeType.staff,
    _ => EmployeeType.staff,
  };
}

/// Salary type for an employee.
enum SalaryType {
  monthly,
  daily;

  String get label => switch (this) {
    SalaryType.monthly => 'Monthly',
    SalaryType.daily => 'Per Day',
  };

  static SalaryType fromString(String value) => switch (value) {
    'monthly' => SalaryType.monthly,
    'daily' => SalaryType.daily,
    _ => SalaryType.monthly,
  };
}

/// Attendance status for a single day.
enum AttendanceStatus {
  present,
  absent;

  String get label => switch (this) {
    AttendanceStatus.present => 'Present',
    AttendanceStatus.absent => 'Absent',
  };

  String get shortLabel => switch (this) {
    AttendanceStatus.present => 'P',
    AttendanceStatus.absent => 'A',
  };

  static AttendanceStatus fromString(String value) => switch (value) {
    'present' => AttendanceStatus.present,
    'absent' => AttendanceStatus.absent,
    _ => AttendanceStatus.present,
  };
}
