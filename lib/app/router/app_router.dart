import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleettrack/app/shell/app_shell.dart';
import 'package:fleettrack/features/attendance/presentation/screens/daily_attendance_screen.dart';
import 'package:fleettrack/features/auth/presentation/providers/auth_provider.dart';
import 'package:fleettrack/features/auth/presentation/screens/login_screen.dart';
import 'package:fleettrack/features/employees/domain/employee_enums.dart';
import 'package:fleettrack/features/employees/presentation/screens/fleet_staff_list_screen.dart';
import 'package:fleettrack/features/monthly_register/presentation/screens/monthly_register_screen.dart';
import 'package:fleettrack/features/payroll/presentation/screens/salary_payroll_screen.dart';
import 'package:fleettrack/features/settings/presentation/screens/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: isAuthenticated ? '/daily' : '/login',
    redirect: (context, state) {
      final isLoggingIn = state.uri.toString() == '/login';
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      if (isAuthenticated && isLoggingIn) {
        return '/daily';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/daily',
            builder: (context, state) => const DailyAttendanceScreen(),
          ),
          GoRoute(
            path: '/monthly',
            builder: (context, state) => const MonthlyRegisterScreen(),
          ),
          GoRoute(
            path: '/payroll',
            builder: (context, state) => const SalaryPayrollScreen(),
          ),
          GoRoute(
            path: '/drivers',
            builder: (context, state) => const FleetStaffListScreen(
              employeeType: EmployeeType.driver,
            ),
          ),
          GoRoute(
            path: '/staff',
            builder: (context, state) => const FleetStaffListScreen(
              employeeType: EmployeeType.staff,
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
