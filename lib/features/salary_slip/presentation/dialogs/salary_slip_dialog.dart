import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:fleettrack/app/theme/app_theme.dart';
import 'package:fleettrack/core/utils/formatters.dart';
import 'package:fleettrack/core/utils/salary_calculator.dart';
import 'package:fleettrack/features/employees/domain/employee.dart';
import 'package:fleettrack/features/employees/domain/employee_enums.dart';
import 'package:fleettrack/features/salary_slip/services/salary_slip_pdf_generator.dart';
import 'package:fleettrack/features/settings/domain/company_settings.dart';

class SalarySlipDialog extends StatelessWidget {
  final Employee employee;
  final CompanySettings settings;
  final int year;
  final int month;
  final int presentDays;
  final int absentDays;

  const SalarySlipDialog({
    super.key,
    required this.employee,
    required this.settings,
    required this.year,
    required this.month,
    required this.presentDays,
    required this.absentDays,
  });

  @override
  Widget build(BuildContext context) {
    final stats = SalaryCalculator.calculate(
      salary: employee.salary,
      salaryType: employee.salaryType.name,
      presentDays: presentDays,
      absentDays: absentDays,
      year: year,
      month: month,
      standardMonthDays: settings.standardMonthDays,
    );

    final monthName = AppDateUtils.monthName(month);
    final isDriver = employee.type == EmployeeType.driver;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
        child: Column(
          children: [
            // Dark Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.dark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Employee Salary Voucher / Slip',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final pdfData = await SalarySlipPdfGenerator.generateSalarySlip(
                        employee: employee,
                        settings: settings,
                        year: year,
                        month: month,
                        presentDays: presentDays,
                        absentDays: absentDays,
                      );
                      await Printing.layoutPdf(
                        onLayout: (_) => pdfData,
                        name: 'Salary_Slip_${employee.name}_${monthName}_$year',
                      );
                    },
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print Slip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.dark,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Voucher Body (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Company Header
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_shipping, color: AppTheme.primaryDark, size: 24),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  settings.companyName.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            settings.tagline.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textTertiary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${settings.city} · Tel: ${settings.phone}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'MONTHLY SALARY PAYOUT VOUCHER · $monthName $year',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Employee Profile Box
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isDriver ? 'DRIVER NAME' : 'EMPLOYEE NAME',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textTertiary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      employee.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Contact: ${employee.phone}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'CATEGORY & ROLE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textTertiary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isDriver
                                          ? 'Commercial Transport Driver'
                                          : 'Operations & Logistics Staff',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      'Joined: ${employee.joinedDate}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (isDriver &&
                              employee.vehicleName != null &&
                              employee.vehicleName!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7), // amber-100
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ASSIGNED VEHICLE / TRUCK DETAILS',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '🚛 ${employee.vehicleName}',
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

                          if (employee.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              isDriver
                                  ? 'Route / Duties: ${employee.description}'
                                  : 'Role / Description: ${employee.description}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Attendance Record Summary
                    const Text(
                      'MONTHLY ATTENDANCE RECORD',
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
                          child: _buildMetricTile(
                            label: 'Total Days In Month',
                            value: '${stats.totalDays}',
                            color: AppTheme.textPrimary,
                            bgColor: AppTheme.surface,
                            borderColor: AppTheme.border,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Days Present [P]',
                            value: '${stats.presentDays} Days',
                            color: AppTheme.success,
                            bgColor: AppTheme.successBg,
                            borderColor: const Color(0xFFA7F3D0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Days Absent [A]',
                            value: '${stats.absentDays} Days',
                            color: AppTheme.danger,
                            bgColor: AppTheme.dangerBg,
                            borderColor: const Color(0xFFFECDD3),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Salary Breakdown Table
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Container(
                            color: AppTheme.surface,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    'SALARY HEAD / ITEM',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'CALCULATION BASIS',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'AMOUNT',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildTableRow(
                            title: 'Base Salary (${employee.salaryType.label})',
                            basis: employee.salaryType == SalaryType.monthly
                                ? 'Standard ${settings.standardMonthDays} Days'
                                : 'Per Day Contract',
                            amount: CurrencyUtils.format(employee.salary, settings.currency),
                          ),
                          _buildTableRow(
                            title: 'Calculated Daily Rate',
                            basis: employee.salaryType == SalaryType.monthly
                                ? '${CurrencyUtils.format(employee.salary, settings.currency)} ÷ ${settings.standardMonthDays} days'
                                : 'Daily Rate',
                            amount: '${CurrencyUtils.format(stats.dailyRate, settings.currency)} / day',
                          ),
                          _buildTableRow(
                            title: 'Earned Attendance (${stats.presentDays} Days Present)',
                            basis: '${stats.presentDays} days × ${CurrencyUtils.format(stats.dailyRate, settings.currency)}',
                            amount: CurrencyUtils.format(stats.payableSalary, settings.currency),
                            textColor: AppTheme.success,
                            isBold: true,
                          ),
                          Container(
                            color: AppTheme.dark,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Row(
                              children: [
                                const Expanded(
                                  flex: 4,
                                  child: Text(
                                    'NET PAYABLE SALARY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  flex: 3,
                                  child: Text(
                                    'ONLY FOR PRESENT DAYS',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    CurrencyUtils.format(stats.payableSalary, settings.currency),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Signature Boxes
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                height: 40,
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                employee.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                isDriver ? 'Driver Signature' : 'Employee Signature',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                height: 40,
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'FOR ${settings.companyName.toUpperCase()}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const Text(
                                'Authorized Transport Manager',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 10, color: AppTheme.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'System generated commercial transport attendance voucher · Valid with authorized stamp',
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
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

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow({
    required String title,
    required String basis,
    required String amount,
    Color textColor = AppTheme.textPrimary,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              basis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
