import 'package:fleettrack/features/employees/domain/employee_enums.dart';

/// Employee model matching the original TypeScript Employee interface.
class Employee {
  final String id;
  final String name;
  final EmployeeType type;
  final String? vehicleName;
  final String description;
  final String phone;
  final double salary;
  final SalaryType salaryType;
  final String joinedDate; // YYYY-MM-DD
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Employee({
    required this.id,
    required this.name,
    required this.type,
    this.vehicleName,
    required this.description,
    required this.phone,
    required this.salary,
    required this.salaryType,
    required this.joinedDate,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from Supabase row.
  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] as String,
    name: json['name'] as String,
    type: EmployeeType.fromString(json['type'] as String),
    vehicleName: json['vehicle_name'] as String?,
    description: json['description'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    salary: (json['salary'] as num).toDouble(),
    salaryType: SalaryType.fromString(json['salary_type'] as String),
    joinedDate: json['joined_date'] as String,
    active: json['active'] as bool? ?? true,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null,
  );

  /// Convert to Supabase insert/update map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'vehicle_name': vehicleName,
    'description': description,
    'phone': phone,
    'salary': salary,
    'salary_type': salaryType.name,
    'joined_date': joinedDate,
    'active': active,
  };

  /// Create from legacy JSON backup format.
  factory Employee.fromLegacyJson(Map<String, dynamic> json) => Employee(
    id: json['id'] as String,
    name: json['name'] as String,
    type: EmployeeType.fromString(json['type'] as String),
    vehicleName: json['vehicleName'] as String?,
    description: json['description'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    salary: (json['salary'] as num).toDouble(),
    salaryType: SalaryType.fromString(json['salaryType'] as String),
    joinedDate: json['joinedDate'] as String,
    active: json['active'] as bool? ?? true,
  );

  /// Convert to legacy JSON backup format.
  Map<String, dynamic> toLegacyJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'vehicleName': vehicleName,
    'description': description,
    'phone': phone,
    'salary': salary,
    'salaryType': salaryType.name,
    'joinedDate': joinedDate,
    'active': active,
  };

  Employee copyWith({
    String? id,
    String? name,
    EmployeeType? type,
    String? vehicleName,
    String? description,
    String? phone,
    double? salary,
    SalaryType? salaryType,
    String? joinedDate,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Employee(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        vehicleName: vehicleName ?? this.vehicleName,
        description: description ?? this.description,
        phone: phone ?? this.phone,
        salary: salary ?? this.salary,
        salaryType: salaryType ?? this.salaryType,
        joinedDate: joinedDate ?? this.joinedDate,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
