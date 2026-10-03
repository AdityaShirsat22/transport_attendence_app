import 'package:flutter/material.dart';
import 'package:fleettrack/app/theme/app_theme.dart';
import 'package:fleettrack/core/utils/formatters.dart';
import 'package:fleettrack/features/employees/domain/employee.dart';
import 'package:fleettrack/features/employees/domain/employee_enums.dart';
import 'package:fleettrack/features/settings/domain/company_settings.dart';

class EmployeeFormDialog extends StatefulWidget {
  final Employee? initialEmployee;
  final EmployeeType defaultType;
  final CompanySettings settings;
  final ValueChanged<Employee> onSave;

  const EmployeeFormDialog({
    super.key,
    this.initialEmployee,
    this.defaultType = EmployeeType.driver,
    required this.settings,
    required this.onSave,
  });

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late EmployeeType _type;
  late SalaryType _salaryType;
  late TextEditingController _nameController;
  late TextEditingController _vehicleController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _salaryController;

  @override
  void initState() {
    super.initState();
    final emp = widget.initialEmployee;
    if (emp != null) {
      _type = emp.type;
      _salaryType = emp.salaryType;
      _nameController = TextEditingController(text: emp.name);
      _vehicleController = TextEditingController(text: emp.vehicleName ?? '');
      _descriptionController = TextEditingController(text: emp.description);
      _phoneController = TextEditingController(text: emp.phone == 'N/A' ? '' : emp.phone);
      _salaryController = TextEditingController(text: emp.salary.toStringAsFixed(0));
    } else {
      _type = widget.defaultType;
      _salaryType = SalaryType.monthly;
      _nameController = TextEditingController();
      _vehicleController = TextEditingController();
      _descriptionController = TextEditingController(
        text: _type == EmployeeType.driver
            ? 'Heavy Commercial Vehicle Driver'
            : 'Transport Operations Staff',
      );
      _phoneController = TextEditingController();
      _salaryController = TextEditingController(
        text: _type == EmployeeType.driver ? '32000' : '22000',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _vehicleController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final vehicle = _vehicleController.text.trim();
    final description = _descriptionController.text.trim();
    final phone = _phoneController.text.trim();
    final salary = double.tryParse(_salaryController.text) ?? 0;

    if (_type == EmployeeType.driver && vehicle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify the assigned vehicle for the driver'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    final emp = Employee(
      id: widget.initialEmployee?.id ?? 'emp-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: _type,
      vehicleName: _type == EmployeeType.driver ? vehicle : null,
      description: description,
      phone: phone.isEmpty ? 'N/A' : phone,
      salary: salary,
      salaryType: _salaryType,
      joinedDate: widget.initialEmployee?.joinedDate ?? AppDateUtils.todayKey(),
      active: widget.initialEmployee?.active ?? true,
    );

    widget.onSave(emp);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialEmployee != null;
    final isDriver = _type == EmployeeType.driver;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dark Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppTheme.dark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isDriver ? Icons.local_shipping : Icons.people,
                    color: isDriver ? AppTheme.primary : const Color(0xFF60A5FA),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEditing
                          ? 'Edit Details'
                          : isDriver
                              ? 'Add Transport Driver'
                              : 'Add Staff Member',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Selector
                      const Text(
                        'CATEGORY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _type = EmployeeType.driver;
                                  if (_descriptionController.text == 'Transport Operations Staff') {
                                    _descriptionController.text = 'Heavy Commercial Vehicle Driver';
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDriver ? const Color(0xFFFFFBEB) : AppTheme.surface,
                                  border: Border.all(
                                    color: isDriver ? AppTheme.primary : AppTheme.border,
                                    width: isDriver ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.local_shipping,
                                      size: 18,
                                      color: isDriver ? AppTheme.primaryDark : AppTheme.textTertiary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Driver (with Vehicle)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDriver ? const Color(0xFF78350F) : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _type = EmployeeType.staff;
                                  if (_descriptionController.text == 'Heavy Commercial Vehicle Driver') {
                                    _descriptionController.text = 'Transport Operations Staff';
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !isDriver ? const Color(0xFFEFF6FF) : AppTheme.surface,
                                  border: Border.all(
                                    color: !isDriver ? const Color(0xFF3B82F6) : AppTheme.border,
                                    width: !isDriver ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 18,
                                      color: Color(0xFF2563EB),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Staff (with Role)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Name Field
                      Text(
                        isDriver ? 'DRIVER FULL NAME *' : 'EMPLOYEE FULL NAME *',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: isDriver ? 'e.g. Ramesh Patil' : 'e.g. Deepak Verma',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Please enter full name' : null,
                      ),

                      // Vehicle Field (Driver only)
                      if (isDriver) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ASSIGNED VEHICLE NAME & REG NO. *',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _vehicleController,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Tata Signa 4825.T (MH 12 QX 4521)',
                                  prefixIcon: Icon(Icons.local_shipping, color: Color(0xFFB45309)),
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  if (_type == EmployeeType.driver &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Please enter vehicle and registration number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Specify truck brand, model, tempo, or registration plate.',
                                style: TextStyle(fontSize: 10, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Description / Role Field
                      Text(
                        isDriver
                            ? 'DRIVER ROUTE / EXPERIENCE / DETAILS *'
                            : 'EMPLOYEE ROLE & DESCRIPTION *',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: isDriver
                              ? 'e.g. Long Haul Container Driver - North Corridor'
                              : 'e.g. Fleet Mechanic / Loading Supervisor / Bilty Dispatcher',
                          prefixIcon: const Icon(Icons.description_outlined, color: AppTheme.textMuted),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Please enter role or duties description'
                            : null,
                      ),

                      const SizedBox(height: 16),

                      // Phone Field
                      const Text(
                        'CONTACT PHONE NUMBER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '+91 98220 12345',
                          prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textMuted),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Individual Salary Rate Section
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'INDIVIDUAL SALARY RATE *',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.borderLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildSalaryTypeBtn(
                                      label: 'Monthly Fixed',
                                      isSelected: _salaryType == SalaryType.monthly,
                                      onTap: () => setState(() => _salaryType = SalaryType.monthly),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildSalaryTypeBtn(
                                      label: 'Per Day Wage',
                                      isSelected: _salaryType == SalaryType.daily,
                                      onTap: () => setState(() => _salaryType = SalaryType.daily),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _salaryController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              decoration: InputDecoration(
                                prefixText: '${widget.settings.currency} ',
                                prefixStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                suffixText: _salaryType == SalaryType.monthly ? '/ month' : '/ day',
                                suffixStyle: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textTertiary,
                                ),
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter salary amount';
                                }
                                final num = double.tryParse(value);
                                if (num == null || num <= 0) {
                                  return 'Please enter a valid salary amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 6),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _salaryController,
                              builder: (context, val, _) {
                                final amt = double.tryParse(val.text) ?? 0;
                                return Text(
                                  _salaryType == SalaryType.monthly
                                      ? 'Calculated as: (${widget.settings.currency} $amt ÷ ${widget.settings.standardMonthDays} days) × Days Present'
                                      : 'Calculated as: ${widget.settings.currency} $amt × Days Present',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Dialog Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.dark,
                    ),
                    child: Text(isEditing ? 'Save Changes' : 'Add to Fleet'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryTypeBtn({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.textPrimary : AppTheme.textTertiary,
          ),
        ),
      ),
    );
  }
}
