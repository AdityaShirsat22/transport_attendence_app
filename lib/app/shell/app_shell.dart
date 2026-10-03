import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleettrack/app/theme/app_theme.dart';
import 'package:fleettrack/core/providers/navigation_providers.dart';
import 'package:fleettrack/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:fleettrack/features/auth/presentation/providers/auth_provider.dart';
import 'package:fleettrack/features/employees/domain/employee_enums.dart';
import 'package:fleettrack/features/employees/presentation/dialogs/employee_form_dialog.dart';
import 'package:fleettrack/features/employees/presentation/providers/employees_provider.dart';
import 'package:fleettrack/features/settings/presentation/providers/settings_provider.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/monthly')) return 1;
    if (location.startsWith('/payroll')) return 2;
    if (location.startsWith('/drivers')) return 3;
    if (location.startsWith('/staff')) return 4;
    return 0; // /daily
  }

  void _onItemTapped(int index, BuildContext context, WidgetRef ref) {
    ref.read(navigationIndexProvider.notifier).state = index;
    switch (index) {
      case 0:
        context.go('/daily');
        break;
      case 1:
        context.go('/monthly');
        break;
      case 2:
        context.go('/payroll');
        break;
      case 3:
        context.go('/drivers');
        break;
      case 4:
        context.go('/staff');
        break;
    }
  }

  void _openAddEmployee(BuildContext context, WidgetRef ref, EmployeeType type) {
    final settings = ref.read(companySettingsProvider).value;
    if (settings == null) return;

    showDialog(
      context: context,
      builder: (context) => EmployeeFormDialog(
        defaultType: type,
        settings: settings,
        onSave: (emp) {
          ref.read(employeesProvider.notifier).saveEmployee(emp);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${emp.name} added successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final settings = ref.watch(companySettingsProvider).value;
    final selectedDate = ref.watch(selectedDateProvider);
    final attendanceMap = ref.watch(attendanceProvider).value ?? {};
    final employees = ref.watch(employeesProvider).value ?? [];

    final activeEmployees = employees.where((e) => e.active).toList();
    final todayRecord = attendanceMap[selectedDate] ?? {};

    int todayPresent = 0;
    for (final emp in activeEmployees) {
      if (todayRecord[emp.id] == AttendanceStatus.present) {
        todayPresent++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_shipping, color: AppTheme.dark, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FLEETTRACK',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    settings?.companyName ?? 'National Roadlines & Transport Co.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Live Present Counter Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF064E3B),
              border: Border.all(color: const Color(0xFF047857)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34D399),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$todayPresent / ${activeEmployees.length} Present',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF34D399),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Quick Add Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
            tooltip: 'Add Workforce Member',
            onSelected: (val) {
              if (val == 'driver') {
                _openAddEmployee(context, ref, EmployeeType.driver);
              } else if (val == 'staff') {
                _openAddEmployee(context, ref, EmployeeType.staff);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'driver',
                child: Row(
                  children: [
                    Icon(Icons.local_shipping, size: 18, color: AppTheme.primaryDark),
                    SizedBox(width: 8),
                    Text('Add Driver with Vehicle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'staff',
                child: Row(
                  children: [
                    Icon(Icons.people, size: 18, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text('Add Staff with Role'),
                  ],
                ),
              ),
            ],
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.white70),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(index, context, ref),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today_outlined),
            activeIcon: Icon(Icons.today),
            label: 'Daily',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_on_outlined),
            activeIcon: Icon(Icons.grid_on),
            label: 'Register',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments),
            label: 'Payroll',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Drivers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Staff',
          ),
        ],
      ),
    );
  }
}
