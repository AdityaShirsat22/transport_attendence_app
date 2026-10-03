import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fleettrack/core/utils/formatters.dart';
import 'package:fleettrack/core/utils/salary_calculator.dart';
import 'package:fleettrack/features/employees/domain/employee.dart';
import 'package:fleettrack/features/employees/domain/employee_enums.dart';
import 'package:fleettrack/features/settings/domain/company_settings.dart';

class SalarySlipPdfGenerator {
  SalarySlipPdfGenerator._();

  static Future<Uint8List> generateSalarySlip({
    required Employee employee,
    required CompanySettings settings,
    required int year,
    required int month,
    required int presentDays,
    required int absentDays,
  }) async {
    final pdf = pw.Document();

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
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Company Header
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey900, width: 2),
                  ),
                ),
                padding: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Column(
                  children: [
                    pw.Text(
                      settings.companyName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      settings.tagline.toUpperCase(),
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${settings.city} · Tel: ${settings.phone}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'MONTHLY SALARY PAYOUT VOUCHER · $monthName $year',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Employee & Vehicle / Role Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                employee.type == EmployeeType.driver
                                    ? 'DRIVER NAME'
                                    : 'EMPLOYEE NAME',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey600,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                employee.name,
                                style: pw.TextStyle(
                                  fontSize: 13,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey900,
                                ),
                              ),
                              pw.Text(
                                'Contact: ${employee.phone}',
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'CATEGORY & ROLE',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey600,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                employee.type == EmployeeType.driver
                                    ? 'Commercial Transport Driver'
                                    : 'Operations & Logistics Staff',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey800,
                                ),
                              ),
                              pw.Text(
                                'Joined: ${employee.joinedDate}',
                                style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (employee.type == EmployeeType.driver &&
                        employee.vehicleName != null &&
                        employee.vehicleName!.isNotEmpty) ...[
                      pw.SizedBox(height: 8),
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.amber50,
                          border: pw.Border.all(color: PdfColors.amber200),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'ASSIGNED VEHICLE / TRUCK DETAILS',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.amber900,
                              ),
                            ),
                            pw.Text(
                              'Transport: ${employee.vehicleName}',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (employee.description.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Text(
                        employee.type == EmployeeType.driver
                            ? 'Route / Duties: ${employee.description}'
                            : 'Role / Description: ${employee.description}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Attendance Summary Boxes
              pw.Text(
                'MONTHLY ATTENDANCE RECORD ($monthName $year)',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildMetricBox(
                      title: 'Total Days in Month',
                      value: '${stats.totalDays}',
                      bgColor: PdfColors.grey100,
                      borderColor: PdfColors.grey300,
                      textColor: PdfColors.grey900,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: _buildMetricBox(
                      title: 'Days Present [P]',
                      value: '${stats.presentDays} Days',
                      bgColor: PdfColors.green50,
                      borderColor: PdfColors.green300,
                      textColor: PdfColors.green900,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: _buildMetricBox(
                      title: 'Days Absent [A]',
                      value: '${stats.absentDays} Days',
                      bgColor: PdfColors.red50,
                      borderColor: PdfColors.red300,
                      textColor: PdfColors.red900,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // Salary Breakdown Table
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  children: [
                    // Header
                    pw.Container(
                      color: PdfColors.grey200,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 4,
                            child: pw.Text(
                              'SALARY HEAD / ITEM',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              'CALCULATION BASIS',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              'AMOUNT',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Rows
                    _buildSalaryRow(
                      head: 'Base Salary (${employee.salaryType.label})',
                      basis: employee.salaryType == SalaryType.monthly
                          ? 'Standard ${settings.standardMonthDays} Days'
                          : 'Per Day Wage',
                      amount: CurrencyUtils.format(employee.salary, settings.currency),
                      isBold: false,
                    ),
                    _buildSalaryRow(
                      head: 'Calculated Daily Rate',
                      basis: employee.salaryType == SalaryType.monthly
                          ? '${CurrencyUtils.format(employee.salary, settings.currency)} ÷ ${settings.standardMonthDays} days'
                          : 'Daily Wage Rate',
                      amount: '${CurrencyUtils.format(stats.dailyRate, settings.currency)} / day',
                      isBold: false,
                    ),
                    _buildSalaryRow(
                      head: 'Earned Attendance (${stats.presentDays} Days Present)',
                      basis: '${stats.presentDays} days × ${CurrencyUtils.format(stats.dailyRate, settings.currency)}',
                      amount: CurrencyUtils.format(stats.payableSalary, settings.currency),
                      isBold: false,
                      color: PdfColors.green900,
                    ),

                    // Net Payable Highlight
                    pw.Container(
                      color: PdfColors.grey900,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 4,
                            child: pw.Text(
                              'NET PAYABLE SALARY',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              'ONLY FOR PRESENT DAYS',
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey400,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              CurrencyUtils.format(stats.payableSalary, settings.currency),
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.amber400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signatures & Stamp
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 16),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(
                      color: PdfColors.grey400,
                      width: 1,
                      style: pw.BorderStyle.dashed,
                    ),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Container(
                            height: 35,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(color: PdfColors.grey400),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            employee.name.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey900,
                            ),
                          ),
                          pw.Text(
                            employee.type == EmployeeType.driver
                                ? 'Driver Signature'
                                : 'Employee Signature',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 48),
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Container(
                            height: 35,
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(color: PdfColors.grey400),
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'FOR ${settings.companyName.toUpperCase()}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey900,
                            ),
                          ),
                          pw.Text(
                            'Authorized Transport Manager / Fleet Incharge',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text(
                  'System generated commercial transport attendance voucher · Valid with authorized stamp',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMetricBox({
    required String title,
    required String value,
    required PdfColor bgColor,
    required PdfColor borderColor,
    required PdfColor textColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: pw.Border.all(color: borderColor),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSalaryRow({
    required String head,
    required String basis,
    required String amount,
    required bool isBold,
    PdfColor color = PdfColors.grey900,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey200),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 4,
            child: pw.Text(
              head,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color,
              ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              basis,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              amount,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
