import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleettrack/app/theme/app_theme.dart';
import 'package:fleettrack/core/utils/formatters.dart';
import 'package:fleettrack/features/employees/domain/employee.dart';
import 'package:fleettrack/features/employees/domain/employee_enums.dart';
import 'package:fleettrack/features/employees/presentation/dialogs/employee_form_dialog.dart';
import 'package:fleettrack/features/employees/presentation/providers/employees_provider.dart';
import 'package:fleettrack/features/settings/presentation/providers/settings_provider.dart';

class FleetStaffListScreen extends ConsumerStatefulWidget {
  final EmployeeType employeeType;

  const FleetStaffListScreen({
    super.key,
    required this.employeeType,
  });

  @override
  ConsumerState<FleetStaffListScreen> createState() => _FleetStaffListScreenState();
}

class _FleetStaffListScreenState extends ConsumerState<FleetStaffListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _confirmDeleteId;
  Timer? _deleteTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _deleteTimer?.cancel();
    super.dispose();
  }

  void _handleDeleteClick(String id) {
    if (_confirmDeleteId == id) {
      ref.read(employeesProvider.notifier).deleteEmployee(id);
      setState(() {
        _confirmDeleteId = null;
      });
      _deleteTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Employee removed successfully'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } else {
      setState(() {
        _confirmDeleteId = id;
      });
      _deleteTimer?.cancel();
      _deleteTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _confirmDeleteId = null;
          });
        }
      });
    }
  }

  void _openAddModal() {
    final settings = ref.read(companySettingsProvider).value;
    if (settings == null) return;

    showDialog(
      context: context,
      builder: (context) => EmployeeFormDialog(
        defaultType: widget.employeeType,
        settings: settings,
        onSave: (newEmp) {
          ref.read(employeesProvider.notifier).saveEmployee(newEmp);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newEmp.name} added to workforce'),
              backgroundColor: AppTheme.success,
            ),
          );
        },
      ),
    );
  }

  void _openEditModal(Employee emp) {
    final settings = ref.read(companySettingsProvider).value;
    if (settings == null) return;

    showDialog(
      context: context,
      builder: (context) => EmployeeFormDialog(
        initialEmployee: emp,
        defaultType: emp.type,
        settings: settings,
        onSave: (updatedEmp) {
          ref.read(employeesProvider.notifier).saveEmployee(updatedEmp);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${updatedEmp.name} details updated'),
              backgroundColor: AppTheme.success,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = widget.employeeType == EmployeeType.driver;
    final employeesAsync = ref.watch(employeesProvider);
    final settings = ref.watch(companySettingsProvider).value;

    return employeesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading employees: $e')),
      data: (allEmployees) {
        final list = allEmployees.where((e) => e.type == widget.employeeType).toList();

        final filtered = list.where((emp) {
          if (_searchQuery.trim().isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          final matchName = emp.name.toLowerCase().contains(q);
          final matchVehicle = emp.vehicleName?.toLowerCase().contains(q) ?? false;
          final matchDesc = emp.description.toLowerCase().contains(q);
          final matchPhone = emp.phone.toLowerCase().contains(q);
          return matchName || matchVehicle || matchDesc || matchPhone;
        }).toList();

        return RefreshIndicator(
          onRefresh: () => ref.read(employeesProvider.notifier).loadEmployees(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDriver
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isDriver ? Icons.local_shipping : Icons.people,
                                color: isDriver
                                    ? AppTheme.primaryDark
                                    : const Color(0xFF2563EB),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isDriver
                                    ? 'Fleet Drivers & Assigned Vehicles'
                                    : 'Transport Operations & Office Staff',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isDriver
                              ? 'Every driver is paired with their commercial truck / tempo and individual wage rate'
                              : 'Non-driving crew members, mechanics, supervisors, billing accountants with descriptions',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openAddModal,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(
                              isDriver
                                  ? 'Add New Driver & Vehicle'
                                  : 'Add New Staff Member',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDriver
                                  ? AppTheme.primary
                                  : const Color(0xFF2563EB),
                              foregroundColor: isDriver ? AppTheme.dark : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Search Bar & Count
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: isDriver
                              ? 'Search driver name, truck model, plate...'
                              : 'Search employee name or description...',
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Total: ${filtered.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Employee Cards
                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isDriver ? Icons.local_shipping_outlined : Icons.people_outline,
                          size: 48,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No ${isDriver ? 'drivers' : 'staff'} found',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Click the add button above to create one',
                          style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final emp = filtered[index];
                      final isDeleting = _confirmDeleteId == emp.id;
                      final standardDays = settings?.standardMonthDays ?? 30;
                      final dailyWage = emp.salaryType == SalaryType.daily
                          ? emp.salary
                          : (emp.salary / standardDays).roundToDouble();

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Bar
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: isDriver
                                          ? const Color(0xFFFEF3C7)
                                          : const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isDriver ? Icons.local_shipping : Icons.people,
                                      color: isDriver
                                          ? AppTheme.primaryDark
                                          : const Color(0xFF2563EB),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          emp.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone_outlined, size: 12, color: AppTheme.textTertiary),
                                            const SizedBox(width: 4),
                                            Text(
                                              emp.phone,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    onPressed: () => _openEditModal(emp),
                                    color: AppTheme.textTertiary,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Edit Worker Details',
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: Icon(
                                      isDeleting ? Icons.delete_forever : Icons.delete_outline,
                                      size: 18,
                                    ),
                                    onPressed: () => _handleDeleteClick(emp.id),
                                    color: isDeleting ? AppTheme.danger : AppTheme.textTertiary,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: isDeleting ? 'Click again to confirm' : 'Delete',
                                  ),
                                ],
                              ),

                              // Confirm Deletion Banner
                              if (isDeleting) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dangerBg,
                                    border: Border.all(color: const Color(0xFFFECDD3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.danger),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'Confirm deletion?',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.danger,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _handleDeleteClick(emp.id),
                                        child: const Text(
                                          'Yes, Delete',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.danger,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Assigned Vehicle Box (for drivers)
                              if (isDriver &&
                                  emp.vehicleName != null &&
                                  emp.vehicleName!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ASSIGNED VEHICLE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF92400E),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '🚛 ${emp.vehicleName}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF451A03),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Description / Role Box
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  border: Border.all(color: AppTheme.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isDriver ? 'ROUTE / DUTIES' : 'JOB DESCRIPTION & ROLE',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textTertiary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      emp.description,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),

                              // Bottom Salary Rate Footer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'INDIVIDUAL SALARY',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textTertiary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text.rich(
                                        TextSpan(
                                          text: CurrencyUtils.format(
                                            emp.salary,
                                            settings?.currency ?? '₹',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.textPrimary,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: emp.salaryType == SalaryType.monthly
                                                  ? '/mo'
                                                  : '/day',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.normal,
                                                color: AppTheme.textTertiary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'DAILY WAGE RATE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textTertiary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '~${CurrencyUtils.format(dailyWage, settings?.currency ?? '₹')}/day',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
