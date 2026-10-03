import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fleettrack/app/theme/app_theme.dart';
import 'package:fleettrack/core/providers/navigation_providers.dart';
import 'package:fleettrack/core/utils/formatters.dart';
import 'package:fleettrack/core/utils/salary_calculator.dart';
import 'package:fleettrack/features/attendance/domain/attendance_record.dart';
import 'package:fleettrack/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:fleettrack/features/employees/domain/employee.dart';
import 'package:fleettrack/features/employees/domain/employee_enums.dart';
import 'package:fleettrack/features/employees/presentation/providers/employees_provider.dart';
import 'package:fleettrack/features/salary_slip/presentation/dialogs/salary_slip_dialog.dart';
import 'package:fleettrack/features/settings/presentation/providers/settings_provider.dart';

class SalaryPayrollScreen extends ConsumerStatefulWidget {
  const SalaryPayrollScreen({super.key});

  @override
  ConsumerState<SalaryPayrollScreen> createState() => _SalaryPayrollScreenState();
}

class _SalaryPayrollScreenState extends ConsumerState<SalaryPayrollScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'driver', 'staff'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _shiftMonth(int delta) {
    int year = ref.read(selectedYearProvider);
    int month = ref.read(selectedMonthProvider);

    month += delta;
    if (month > 12) {
      month = 1;
      year += 1;
    } else if (month < 1) {
      month = 12;
      year -= 1;
    }

    ref.read(selectedYearProvider.notifier).state = year;
    ref.read(selectedMonthProvider.notifier).state = month;
  }

  Future<void> _printPayrollSheet({
    required List<Employee> employees,
    required MonthlyAttendanceMap attendanceRecord,
    required int year,
    required int month,
    required int daysInMonth,
    required int standardMonthDays,
    required String companyName,
    required String currency,
    required double totalNetPayout,
    required double totalDriverWages,
    required double totalStaffWages,
  }) async {
    final pdf = pw.Document();
    final monthName = AppDateUtils.monthName(month);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyName.toUpperCase(),
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Monthly Salary Payroll Statement · $monthName $year',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'NET PAYOUT: ${CurrencyUtils.format(totalNetPayout, currency)}',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Drivers: ${CurrencyUtils.format(totalDriverWages, currency)} · Staff: ${CurrencyUtils.format(totalStaffWages, currency)}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Employee Name', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Vehicle / Role', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Base Rate', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Daily Rate', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Present', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Absent', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Net Payable', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...employees.map((emp) {
                    int p = 0;
                    int a = 0;
                    for (int d = 1; d <= daysInMonth; d++) {
                      final dateKey = AppDateUtils.buildDateKey(year, month, d);
                      final status = attendanceRecord[dateKey]?[emp.id];
                      if (status == AttendanceStatus.present) {
                        p++;
                      } else if (status == AttendanceStatus.absent) {
                        a++;
                      }
                    }

                    final stats = SalaryCalculator.calculate(
                      salary: emp.salary,
                      salaryType: emp.salaryType.name,
                      presentDays: p,
                      absentDays: a,
                      year: year,
                      month: month,
                      standardMonthDays: standardMonthDays,
                    );

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(emp.name, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            emp.type == EmployeeType.driver && emp.vehicleName != null
                                ? emp.vehicleName!
                                : emp.description,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(CurrencyUtils.format(emp.salary, currency), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(CurrencyUtils.format(stats.dailyRate, currency), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('$p', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('$a', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(CurrencyUtils.format(stats.payableSalary, currency), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: 'Payroll_Statement_${monthName}_$year',
    );
  }

  @override
  Widget build(BuildContext context) {
    final year = ref.watch(selectedYearProvider);
    final month = ref.watch(selectedMonthProvider);
    final employeesAsync = ref.watch(employeesProvider);
    final attendanceAsync = ref.watch(attendanceProvider);
    final settings = ref.watch(companySettingsProvider).value;

    final daysInMonth = AppDateUtils.daysInMonth(year, month);
    final monthName = AppDateUtils.monthName(month);

    return employeesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allEmployees) {
        final activeEmployees = allEmployees.where((e) => e.active).toList();
        final attendanceRecord = attendanceAsync.value ?? {};
        final standardDays = settings?.standardMonthDays ?? 30;
        final currency = settings?.currency ?? '₹';

        // Compute payroll stats for all active employees
        final computedList = activeEmployees.map((emp) {
          int presentCount = 0;
          int absentCount = 0;

          for (int d = 1; d <= daysInMonth; d++) {
            final dateKey = AppDateUtils.buildDateKey(year, month, d);
            final status = attendanceRecord[dateKey]?[emp.id];
            if (status == AttendanceStatus.present) {
              presentCount++;
            } else if (status == AttendanceStatus.absent) {
              absentCount++;
            }
          }

          final stats = SalaryCalculator.calculate(
            salary: emp.salary,
            salaryType: emp.salaryType.name,
            presentDays: presentCount,
            absentDays: absentCount,
            year: year,
            month: month,
            standardMonthDays: standardDays,
          );

          return (employee: emp, stats: stats);
        }).toList();

        // Totals
        final totalPayrollPayable =
            computedList.fold<double>(0, (sum, item) => sum + item.stats.payableSalary);
        final totalNominalBudget =
            computedList.fold<double>(0, (sum, item) => sum + item.employee.salary);
        final driverPayout = computedList
            .where((item) => item.employee.type == EmployeeType.driver)
            .fold<double>(0, (sum, item) => sum + item.stats.payableSalary);
        final staffPayout = computedList
            .where((item) => item.employee.type == EmployeeType.staff)
            .fold<double>(0, (sum, item) => sum + item.stats.payableSalary);

        final totalDrivers =
            computedList.where((item) => item.employee.type == EmployeeType.driver).length;
        final totalStaff =
            computedList.where((item) => item.employee.type == EmployeeType.staff).length;
        final absentDeduction =
            (totalNominalBudget - totalPayrollPayable).clamp(0.0, double.infinity);

        // Filtered list
        final filteredList = computedList.where((item) {
          final emp = item.employee;
          if (_filterType == 'driver' && emp.type != EmployeeType.driver) return false;
          if (_filterType == 'staff' && emp.type != EmployeeType.staff) return false;

          if (_searchQuery.trim().isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final matchName = emp.name.toLowerCase().contains(q);
            final matchVehicle = emp.vehicleName?.toLowerCase().contains(q) ?? false;
            final matchDesc = emp.description.toLowerCase().contains(q);
            return matchName || matchVehicle || matchDesc;
          }
          return true;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(attendanceProvider.notifier).loadAttendance();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Month Navigation Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => _shiftMonth(-1),
                              icon: const Icon(Icons.chevron_left),
                              tooltip: 'Previous Month',
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month, color: AppTheme.primaryDark, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '$monthName $year',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () => _shiftMonth(1),
                              icon: const Icon(Icons.chevron_right),
                              tooltip: 'Next Month',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => _printPayrollSheet(
                            employees: filteredList.map((e) => e.employee).toList(),
                            attendanceRecord: attendanceRecord,
                            year: year,
                            month: month,
                            daysInMonth: daysInMonth,
                            standardMonthDays: standardDays,
                            companyName: settings?.companyName ?? 'FleetTrack',
                            currency: currency,
                            totalNetPayout: totalPayrollPayable,
                            totalDriverWages: driverPayout,
                            totalStaffWages: staffPayout,
                          ),
                          icon: const Icon(Icons.print, size: 16),
                          label: const Text('Print Payroll Statement'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dark,
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Financial Overview Cards (2x2 on mobile, 4 in row on tablet)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.darkBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NET MONTHLY PAYOUT (EARNED)',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyUtils.format(totalPayrollPayable, currency),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Strictly from Present days',
                              style: TextStyle(fontSize: 10, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFinancialCard(
                        title: 'TOTAL DRIVER WAGES',
                        value: CurrencyUtils.format(driverPayout, currency),
                        subtitle: '🚛 $totalDrivers Drivers on Fleet',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFinancialCard(
                        title: 'TOTAL STAFF WAGES',
                        value: CurrencyUtils.format(staffPayout, currency),
                        subtitle: '👥 $totalStaff Operations Staff',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFinancialCard(
                        title: 'ABSENT DEDUCTION',
                        value: CurrencyUtils.format(absentDeduction, currency),
                        subtitle: 'Saved on unworked shifts',
                        valueColor: AppTheme.danger,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Filter & Search Controls
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPill('All Workers (${activeEmployees.length})', 'all'),
                            const SizedBox(width: 6),
                            _buildPill('Drivers Only ($totalDrivers)', 'driver'),
                            const SizedBox(width: 6),
                            _buildPill('Staff Only ($totalStaff)', 'staff'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by worker, vehicle, or role...',
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

                const SizedBox(height: 14),

                // Payroll Table
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 700),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.dark),
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 60,
                        horizontalMargin: 12,
                        columnSpacing: 14,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'EMPLOYEE / DRIVER',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'VEHICLE / ROLE',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'BASE SALARY',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'DAILY RATE',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'PRESENT',
                              style: TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'ABSENT',
                              style: TextStyle(color: Color(0xFFFDA4AF), fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'NET PAYABLE',
                              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          DataColumn(
                            label: Center(
                              child: Text(
                                'SLIP',
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                        rows: filteredList.map((item) {
                          final emp = item.employee;
                          final stats = item.stats;
                          final isDriver = emp.type == EmployeeType.driver;

                          return DataRow(
                            cells: [
                              // Name & Badge
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      emp.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: isDriver ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            isDriver ? 'DRIVER' : 'STAFF',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: isDriver ? const Color(0xFF92400E) : const Color(0xFF1E3A8A),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          emp.phone,
                                          style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Vehicle / Role
                              DataCell(
                                SizedBox(
                                  width: 170,
                                  child: isDriver && emp.vehicleName != null
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '🚛 ${emp.vehicleName}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF78350F),
                                              ),
                                            ),
                                            Text(
                                              emp.description,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          emp.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                        ),
                                ),
                              ),
                              // Base Salary
                              DataCell(
                                Text.rich(
                                  TextSpan(
                                    text: CurrencyUtils.format(emp.salary, currency),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    children: [
                                      TextSpan(
                                        text: emp.salaryType == SalaryType.monthly ? '\n/mo' : '\n/day',
                                        style: const TextStyle(fontSize: 9, color: AppTheme.textTertiary, fontWeight: FontWeight.normal),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              // Daily Rate
                              DataCell(
                                Text(
                                  CurrencyUtils.format(stats.dailyRate, currency),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                                ),
                              ),
                              // Present Days
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${stats.presentDays} P',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                ),
                              ),
                              // Absent Days
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dangerBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${stats.absentDays} A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: AppTheme.danger,
                                    ),
                                  ),
                                ),
                              ),
                              // Net Payable
                              DataCell(
                                Text(
                                  CurrencyUtils.format(stats.payableSalary, currency),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              // Slip Button
                              DataCell(
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (settings == null) return;
                                    showDialog(
                                      context: context,
                                      builder: (context) => SalarySlipDialog(
                                        employee: emp,
                                        settings: settings,
                                        year: year,
                                        month: month,
                                        presentDays: stats.presentDays,
                                        absentDays: stats.absentDays,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.print, size: 12),
                                  label: const Text('Slip'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: AppTheme.dark,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required String value,
    required String subtitle,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppTheme.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, String value) {
    final isSelected = _filterType == value;
    return InkWell(
      onTap: () => setState(() => _filterType = value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.dark : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? AppTheme.dark : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
