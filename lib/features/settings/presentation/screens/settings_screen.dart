import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fleettrack/app/theme/app_theme.dart';
import 'package:fleettrack/core/utils/formatters.dart';
import 'package:fleettrack/features/attendance/domain/attendance_record.dart';
import 'package:fleettrack/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:fleettrack/features/employees/domain/employee.dart';
import 'package:fleettrack/features/employees/domain/employee_enums.dart';
import 'package:fleettrack/features/employees/presentation/providers/employees_provider.dart';
import 'package:fleettrack/features/settings/domain/company_settings.dart';
import 'package:fleettrack/features/settings/presentation/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;
  late TextEditingController _currencyController;
  late TextEditingController _monthDaysController;

  bool _resetConfirm = false;
  bool _savedSuccess = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(companySettingsProvider).value ?? const CompanySettings();
    _nameController = TextEditingController(text: settings.companyName);
    _taglineController = TextEditingController(text: settings.tagline);
    _cityController = TextEditingController(text: settings.city);
    _phoneController = TextEditingController(text: settings.phone);
    _currencyController = TextEditingController(text: settings.currency);
    _monthDaysController = TextEditingController(text: settings.standardMonthDays.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _currencyController.dispose();
    _monthDaysController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final current = ref.read(companySettingsProvider).value ?? const CompanySettings();
    final updated = current.copyWith(
      companyName: _nameController.text.trim(),
      tagline: _taglineController.text.trim(),
      city: _cityController.text.trim(),
      phone: _phoneController.text.trim(),
      currency: _currencyController.text.trim(),
      standardMonthDays: int.tryParse(_monthDaysController.text) ?? 30,
    );

    await ref.read(companySettingsProvider.notifier).updateSettings(updated);

    setState(() => _savedSuccess = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _savedSuccess = false);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Company settings saved successfully'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Future<void> _exportBackup() async {
    final settings = ref.read(companySettingsProvider).value ?? const CompanySettings();
    final employees = ref.read(employeesProvider).value ?? [];
    final attendance = ref.read(attendanceProvider).value ?? {};

    // Transform in-memory attendance map to legacy format
    final Map<String, Map<String, String>> legacyAttendance = {};
    for (final dateEntry in attendance.entries) {
      legacyAttendance[dateEntry.key] = {};
      for (final empEntry in dateEntry.value.entries) {
        legacyAttendance[dateEntry.key]![empEntry.key] = empEntry.value.name;
      }
    }

    final backup = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'companySettings': settings.toLegacyJson(),
      'employees': employees.map((e) => e.toLegacyJson()).toList(),
      'attendanceRecord': legacyAttendance,
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
    final dir = await getTemporaryDirectory();
    final dateStr = AppDateUtils.todayKey();
    final file = File('${dir.path}/FleetTrack_Backup_$dateStr.json');
    await file.writeAsString(jsonStr);

    await Share.shareXFiles([XFile(file.path)], text: 'FleetTrack Transport Backup');
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      if (data.containsKey('employees') && data.containsKey('attendanceRecord')) {
        // Restore Employees
        final empListJson = data['employees'] as List;
        final employees = empListJson
            .map((e) => Employee.fromLegacyJson(e as Map<String, dynamic>))
            .toList();

        // Restore Attendance
        final attJson = data['attendanceRecord'] as Map<String, dynamic>;
        final MonthlyAttendanceMap attMap = {};
        for (final dateKey in attJson.keys) {
          attMap[dateKey] = {};
          final dayJson = attJson[dateKey] as Map<String, dynamic>;
          for (final empId in dayJson.keys) {
            attMap[dateKey]![empId] =
                dayJson[empId] == 'absent' ? AttendanceStatus.absent : AttendanceStatus.present;
          }
        }

        // Restore Settings
        if (data.containsKey('companySettings')) {
          final settings = CompanySettings.fromLegacyJson(data['companySettings'] as Map<String, dynamic>);
          await ref.read(companySettingsProvider.notifier).updateSettings(settings);
          _nameController.text = settings.companyName;
          _taglineController.text = settings.tagline;
          _cityController.text = settings.city;
          _phoneController.text = settings.phone;
          _currencyController.text = settings.currency;
          _monthDaysController.text = settings.standardMonthDays.toString();
        }

        await ref.read(employeesProvider.notifier).restoreEmployees(employees);
        await ref.read(attendanceProvider.notifier).restoreAttendance(attMap);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid backup file format'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to import backup: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  void _resetAllDefaults() async {
    await ref.read(companySettingsProvider.notifier).resetToDefaults();

    final defSettings = ref.read(companySettingsProvider).value ?? const CompanySettings();
    _nameController.text = defSettings.companyName;
    _taglineController.text = defSettings.tagline;
    _cityController.text = defSettings.city;
    _phoneController.text = defSettings.phone;
    _currencyController.text = defSettings.currency;
    _monthDaysController.text = defSettings.standardMonthDays.toString();

    setState(() => _resetConfirm = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Company settings reset to defaults'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Business Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.business, color: AppTheme.primaryDark, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Transport Business Details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Company Name
                    const Text('BUSINESS NAME *', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _nameController,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 12),

                    // Tagline
                    const Text('TAGLINE / BUSINESS SPECIALIZATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    TextFormField(controller: _taglineController),

                    const SizedBox(height: 12),

                    // City & Phone
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('OFFICE CITY / HUB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              TextFormField(controller: _cityController),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CONTACT PHONE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              TextFormField(controller: _phoneController),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Currency & Month Days Divisor
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CURRENCY SYMBOL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              TextFormField(controller: _currencyController),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('MONTH DAYS DIVISOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _monthDaysController,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  final n = int.tryParse(v ?? '');
                                  if (n == null || n < 20 || n > 31) {
                                    return 'Enter 20-31';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleSave,
                        icon: Icon(_savedSuccess ? Icons.check : Icons.save, size: 18),
                        label: Text(_savedSuccess ? 'Settings Saved!' : 'Save Business Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _savedSuccess ? AppTheme.success : AppTheme.primary,
                          foregroundColor: _savedSuccess ? Colors.white : AppTheme.dark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Backup & Migration Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud_sync, color: AppTheme.primaryDark, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Data Backup & Migration',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Export complete company data, workforce list, and attendance logs to a JSON file or restore from an earlier backup.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _exportBackup,
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Export JSON'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _importBackup,
                            icon: const Icon(Icons.upload, size: 16),
                            label: const Text('Import Backup'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Danger Zone / Reset Defaults Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.restart_alt, color: AppTheme.danger, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Reset Company Settings',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Reset business details and standard monthly calculation parameters back to defaults.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                    ),
                    const SizedBox(height: 14),
                    if (_resetConfirm)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _resetAllDefaults,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.danger,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Yes, Reset Settings'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () => setState(() => _resetConfirm = false),
                            child: const Text('Cancel'),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _resetConfirm = true),
                        icon: const Icon(Icons.refresh, size: 16, color: AppTheme.danger),
                        label: const Text('Reset Company Settings'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.danger,
                          side: const BorderSide(color: AppTheme.danger),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
