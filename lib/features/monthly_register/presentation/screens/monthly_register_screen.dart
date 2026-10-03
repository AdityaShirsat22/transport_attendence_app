import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
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

class MonthlyRegisterScreen extends ConsumerStatefulWidget {
  const MonthlyRegisterScreen({super.key});

  @override
  ConsumerState<MonthlyRegisterScreen> createState() => _MonthlyRegisterScreenState();
}

class _MonthlyRegisterScreenState extends ConsumerState<MonthlyRegisterScreen> {
  String _filterType = 'all'; // 'all', 'driver', 'staff'

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

  Future<void> _exportCsv({
    required List<Employee> employees,
    required MonthlyAttendanceMap attendanceRecord,
    required int year,
    required int month,
    required int daysInMonth,
    required int standardMonthDays,
    required String currency,
  }) async {
    final daysArray = List.generate(daysInMonth, (i) => i + 1);
    final monthName = AppDateUtils.monthName(month);

    final List<List<dynamic>> rows = [];

    // Header row
    rows.add([
      'Employee Name',
      'Category',
      'Assigned Vehicle / Role Description',
      'Phone',
      'Salary Rate',
      'Salary Type',
      ...daysArray.map((d) => 'Day $d'),
      'Total Present [P]',
      'Total Absent [A]',
      'Payable Salary',
    ]);

    for (final emp in employees) {
      int pCount = 0;
      int aCount = 0;

      final dayStatuses = daysArray.map((d) {
        final dateKey = AppDateUtils.buildDateKey(year, month, d);
        final status = attendanceRecord[dateKey]?[emp.id];
        if (status == AttendanceStatus.present) {
          pCount++;
          return 'P';
        }
        if (status == AttendanceStatus.absent) {
          aCount++;
          return 'A';
        }
        return '-';
      }).toList();

      final stats = SalaryCalculator.calculate(
        salary: emp.salary,
        salaryType: emp.salaryType.name,
        presentDays: pCount,
        absentDays: aCount,
        year: year,
        month: month,
        standardMonthDays: standardMonthDays,
      );

      rows.add([
        emp.name,
        emp.type == EmployeeType.driver ? 'Driver' : 'Staff',
        emp.type == EmployeeType.driver ? (emp.vehicleName ?? '') : emp.description,
        emp.phone,
        emp.salary,
        emp.salaryType.name,
        ...dayStatuses,
        pCount,
        aCount,
        stats.payableSalary,
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Transport_Attendance_${monthName}_$year.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)], text: 'Transport Attendance $monthName $year');
  }

  Future<void> _printRegister({
    required List<Employee> employees,
    required MonthlyAttendanceMap attendanceRecord,
    required int year,
    required int month,
    required int daysInMonth,
    required int standardMonthDays,
    required String companyName,
    required String currency,
  }) async {
    final pdf = pw.Document();
    final monthName = AppDateUtils.monthName(month);
    final daysArray = List.generate(daysInMonth, (i) => i + 1);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(16),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyName.toUpperCase(),
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Monthly Attendance Register · $monthName $year',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Total Workforce: ${employees.length}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Employee', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      ...daysArray.map(
                        (d) => pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text('$d', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('P', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('A', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Payable', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...employees.map((emp) {
                    int pCount = 0;
                    int aCount = 0;

                    final dayCells = daysArray.map((d) {
                      final dateKey = AppDateUtils.buildDateKey(year, month, d);
                      final status = attendanceRecord[dateKey]?[emp.id];
                      String text = '-';
                      if (status == AttendanceStatus.present) {
                        pCount++;
                        text = 'P';
                      } else if (status == AttendanceStatus.absent) {
                        aCount++;
                        text = 'A';
                      }
                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(text, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 6)),
                      );
                    }).toList();

                    final stats = SalaryCalculator.calculate(
                      salary: emp.salary,
                      salaryType: emp.salaryType.name,
                      presentDays: pCount,
                      absentDays: aCount,
                      year: year,
                      month: month,
                      standardMonthDays: standardMonthDays,
                    );

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text(
                            emp.type == EmployeeType.driver && emp.vehicleName != null
                                ? '${emp.name}\n(${emp.vehicleName})'
                                : emp.name,
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ),
                        ...dayCells,
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text('$pCount', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text('$aCount', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(2),
                          child: pw.Text('${stats.payableSalary.toInt()}', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
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
      name: 'Attendance_Register_${monthName}_$year',
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
    final daysArray = List.generate(daysInMonth, (i) => i + 1);

    return employeesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allEmployees) {
        final activeEmployees = allEmployees.where((e) => e.active).toList();
        final filteredEmployees = activeEmployees.where((emp) {
          if (_filterType == 'driver') return emp.type == EmployeeType.driver;
          if (_filterType == 'staff') return emp.type == EmployeeType.staff;
          return true;
        }).toList();

        final attendanceRecord = attendanceAsync.value ?? {};
        final standardDays = settings?.standardMonthDays ?? 30;
        final currency = settings?.currency ?? '₹';

        // Calculate company monthly totals
        double totalCompanyPayout = 0;
        int totalFleetPresentManDays = 0;
        int totalFleetAbsentManDays = 0;

        for (final emp in filteredEmployees) {
          int p = 0;
          int a = 0;
          for (final d in daysArray) {
            final dateKey = AppDateUtils.buildDateKey(year, month, d);
            final status = attendanceRecord[dateKey]?[emp.id];
            if (status == AttendanceStatus.present) {
              p++;
            } else if (status == AttendanceStatus.absent) {
              a++;
            }
          }
          totalFleetPresentManDays += p;
          totalFleetAbsentManDays += a;

          final stats = SalaryCalculator.calculate(
            salary: emp.salary,
            salaryType: emp.salaryType.name,
            presentDays: p,
            absentDays: a,
            year: year,
            month: month,
            standardMonthDays: standardDays,
          );
          totalCompanyPayout += stats.payableSalary;
        }

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
                // Month Navigation & Actions Bar
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
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
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$daysInMonth Days',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textTertiary,
                                    ),
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
                        const Divider(),
                        const SizedBox(height: 8),

                        // Filters & Buttons Row
                        Row(
                          children: [
                            // Filter Pills
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildPill('All (${activeEmployees.length})', 'all'),
                                    const SizedBox(width: 6),
                                    _buildPill('Drivers', 'driver'),
                                    const SizedBox(width: 6),
                                    _buildPill('Staff', 'staff'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Action Buttons
                            OutlinedButton.icon(
                              onPressed: () => _exportCsv(
                                employees: filteredEmployees,
                                attendanceRecord: attendanceRecord,
                                year: year,
                                month: month,
                                daysInMonth: daysInMonth,
                                standardMonthDays: standardDays,
                                currency: currency,
                              ),
                              icon: const Icon(Icons.download, size: 14),
                              label: const Text('CSV'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton.icon(
                              onPressed: () => _printRegister(
                                employees: filteredEmployees,
                                attendanceRecord: attendanceRecord,
                                year: year,
                                month: month,
                                daysInMonth: daysInMonth,
                                standardMonthDays: standardDays,
                                companyName: settings?.companyName ?? 'FleetTrack',
                                currency: currency,
                              ),
                              icon: const Icon(Icons.print, size: 14),
                              label: const Text('Print'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.dark,
                                foregroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Summary Statistics Banner
                Row(
                  children: [
                    Expanded(
                      child: _buildBannerCard(
                        title: 'FLEET PRESENT',
                        value: '$totalFleetPresentManDays Man-Days',
                        subtitle: 'Active worked shifts',
                        color: AppTheme.success,
                        bgColor: AppTheme.successBg,
                        borderColor: const Color(0xFFA7F3D0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBannerCard(
                        title: 'FLEET ABSENT',
                        value: '$totalFleetAbsentManDays Days',
                        subtitle: 'Off days recorded',
                        color: AppTheme.danger,
                        bgColor: AppTheme.dangerBg,
                        borderColor: const Color(0xFFFECDD3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildBannerCard(
                  title: 'CALCULATED NET MONTHLY PAYROLL',
                  value: CurrencyUtils.format(totalCompanyPayout, currency),
                  subtitle: 'Total wages payable strictly based on Present days',
                  color: const Color(0xFF92400E),
                  bgColor: const Color(0xFFFEF3C7),
                  borderColor: const Color(0xFFFDE68A),
                ),

                const SizedBox(height: 14),

                // Matrix Grid Guide Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Tap any day square to cycle status:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                      ),
                      Text('P = Present (Green)', style: TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.bold)),
                      Text('·', style: TextStyle(color: AppTheme.textMuted)),
                      Text('A = Absent (Red)', style: TextStyle(fontSize: 11, color: AppTheme.danger, fontWeight: FontWeight.bold)),
                      Text('·', style: TextStyle(color: AppTheme.textMuted)),
                      Text('- = Empty', style: TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Interactive Matrix Table (Horizontally Scrollable)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 200.0 + 80.0 + (daysInMonth * 34.0) + 48.0 + 48.0 + 95.0 + 50.0,
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.dark),
                        dataRowMinHeight: 46,
                        dataRowMaxHeight: 52,
                        horizontalMargin: 8,
                        columnSpacing: 6,
                        columns: [
                          const DataColumn(
                            label: Text(
                              'WORKER & VEHICLE',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          const DataColumn(
                            numeric: true,
                            label: Text(
                              'RATE',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          ...daysArray.map(
                            (d) => DataColumn(
                              numeric: true,
                              label: Center(
                                child: Text(
                                  '$d',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const DataColumn(
                            numeric: true,
                            label: Text(
                              '[P]',
                              style: TextStyle(color: Color(0xFF6EE7B7), fontWeight: FontWeight.w900, fontSize: 11),
                            ),
                          ),
                          const DataColumn(
                            numeric: true,
                            label: Text(
                              '[A]',
                              style: TextStyle(color: Color(0xFFFDA4AF), fontWeight: FontWeight.w900, fontSize: 11),
                            ),
                          ),
                          const DataColumn(
                            numeric: true,
                            label: Text(
                              'PAYABLE',
                              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 11),
                            ),
                          ),
                          const DataColumn(
                            label: Center(
                              child: Text(
                                'SLIP',
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                        rows: filteredEmployees.map((emp) {
                          int pCount = 0;
                          int aCount = 0;

                          final dayCells = daysArray.map((d) {
                            final dateKey = AppDateUtils.buildDateKey(year, month, d);
                            final status = attendanceRecord[dateKey]?[emp.id];

                            if (status == AttendanceStatus.present) {
                              pCount++;
                            } else if (status == AttendanceStatus.absent) {
                              aCount++;
                            }

                            final isP = status == AttendanceStatus.present;
                            final isA = status == AttendanceStatus.absent;

                            return DataCell(
                              InkWell(
                                onTap: () {
                                  ref.read(attendanceProvider.notifier).toggleCellAttendance(dateKey, emp.id);
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isP
                                        ? AppTheme.success
                                        : isA
                                            ? AppTheme.danger
                                            : AppTheme.surface,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isP ? 'P' : isA ? 'A' : '-',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      color: isP || isA ? Colors.white : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList();

                          final stats = SalaryCalculator.calculate(
                            salary: emp.salary,
                            salaryType: emp.salaryType.name,
                            presentDays: pCount,
                            absentDays: aCount,
                            year: year,
                            month: month,
                            standardMonthDays: standardDays,
                          );

                          final isDriver = emp.type == EmployeeType.driver;

                          return DataRow(
                            cells: [
                              // Worker Info
                              DataCell(
                                SizedBox(
                                  width: 170,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        emp.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        isDriver && emp.vehicleName != null
                                            ? '🚛 ${emp.vehicleName}'
                                            : emp.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDriver ? const Color(0xFF92400E) : AppTheme.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Base Rate
                              DataCell(
                                Text(
                                  CurrencyUtils.format(emp.salary, currency),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                              // Days
                              ...dayCells,
                              // Present
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$pCount',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                ),
                              ),
                              // Absent
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dangerBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$aCount',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppTheme.danger,
                                    ),
                                  ),
                                ),
                              ),
                              // Payable
                              DataCell(
                                Text(
                                  CurrencyUtils.format(stats.payableSalary, currency),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              // Slip Action
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.receipt_outlined, size: 18),
                                  onPressed: () {
                                    if (settings == null) return;
                                    showDialog(
                                      context: context,
                                      builder: (context) => SalarySlipDialog(
                                        employee: emp,
                                        settings: settings,
                                        year: year,
                                        month: month,
                                        presentDays: pCount,
                                        absentDays: aCount,
                                      ),
                                    );
                                  },
                                  tooltip: 'View Salary Voucher',
                                  color: AppTheme.primaryDark,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
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

  Widget _buildPill(String label, String value) {
    final isSelected = _filterType == value;
    return InkWell(
      onTap: () => setState(() => _filterType = value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.dark : AppTheme.surface,
          borderRadius: BorderRadius.circular(6),
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

  Widget _buildBannerCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
