import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleettrack/app/theme/app_theme.dart';
import 'package:fleettrack/core/providers/navigation_providers.dart';
import 'package:fleettrack/core/utils/formatters.dart';
import 'package:fleettrack/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:fleettrack/features/employees/domain/employee_enums.dart';
import 'package:fleettrack/features/employees/presentation/dialogs/employee_form_dialog.dart';
import 'package:fleettrack/features/employees/presentation/providers/employees_provider.dart';
import 'package:fleettrack/features/settings/presentation/providers/settings_provider.dart';

class DailyAttendanceScreen extends ConsumerStatefulWidget {
  const DailyAttendanceScreen({super.key});

  @override
  ConsumerState<DailyAttendanceScreen> createState() => _DailyAttendanceScreenState();
}

class _DailyAttendanceScreenState extends ConsumerState<DailyAttendanceScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'driver', 'staff'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _shiftDate(int days) {
    final currentKey = ref.read(selectedDateProvider);
    try {
      final current = AppDateUtils.fromDateKey(currentKey);
      final next = current.add(Duration(days: days));
      final nextKey = AppDateUtils.toDateKey(next);
      ref.read(selectedDateProvider.notifier).state = nextKey;
      ref.read(selectedYearProvider.notifier).state = next.year;
      ref.read(selectedMonthProvider.notifier).state = next.month;
    } catch (_) {}
  }

  void _pickDate() async {
    final currentKey = ref.read(selectedDateProvider);
    DateTime initial = DateTime.now();
    try {
      initial = AppDateUtils.fromDateKey(currentKey);
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      final newKey = AppDateUtils.toDateKey(picked);
      ref.read(selectedDateProvider.notifier).state = newKey;
      ref.read(selectedYearProvider.notifier).state = picked.year;
      ref.read(selectedMonthProvider.notifier).state = picked.month;
    }
  }

  void _openAddModal(EmployeeType type) {
    final settings = ref.read(companySettingsProvider).value;
    if (settings == null) return;

    showDialog(
      context: context,
      builder: (context) => EmployeeFormDialog(
        defaultType: type,
        settings: settings,
        onSave: (newEmp) {
          ref.read(employeesProvider.notifier).saveEmployee(newEmp);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newEmp.name} added to fleet'),
              backgroundColor: AppTheme.success,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final employeesAsync = ref.watch(employeesProvider);
    final attendanceAsync = ref.watch(attendanceProvider);
    final settings = ref.watch(companySettingsProvider).value;

    DateTime dateObj;
    try {
      dateObj = AppDateUtils.fromDateKey(selectedDate);
    } catch (_) {
      dateObj = DateTime.now();
    }
    final formattedDate = AppDateUtils.formatDisplay(dateObj);

    return employeesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading employees: $e')),
      data: (allEmployees) {
        final activeEmployees = allEmployees.where((e) => e.active).toList();
        final totalCount = activeEmployees.length;

        final attendanceMap = attendanceAsync.value ?? {};
        final todayRecord = attendanceMap[selectedDate] ?? {};

        int presentCount = 0;
        int absentCount = 0;
        int unmarkedCount = 0;

        for (final emp in activeEmployees) {
          final status = todayRecord[emp.id];
          if (status == AttendanceStatus.present) {
            presentCount++;
          } else if (status == AttendanceStatus.absent) {
            absentCount++;
          } else {
            unmarkedCount++;
          }
        }

        final driversCount =
            activeEmployees.where((e) => e.type == EmployeeType.driver).length;
        final staffCount =
            activeEmployees.where((e) => e.type == EmployeeType.staff).length;

        // Filter employees
        final filteredEmployees = activeEmployees.where((emp) {
          if (_filterType == 'driver' && emp.type != EmployeeType.driver) return false;
          if (_filterType == 'staff' && emp.type != EmployeeType.staff) return false;

          if (_searchQuery.trim().isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final matchName = emp.name.toLowerCase().contains(q);
            final matchVehicle = emp.vehicleName?.toLowerCase().contains(q) ?? false;
            final matchDesc = emp.description.toLowerCase().contains(q);
            final matchPhone = emp.phone.toLowerCase().contains(q);
            return matchName || matchVehicle || matchDesc || matchPhone;
          }
          return true;
        }).toList();

        final presentPct = totalCount > 0 ? ((presentCount / totalCount) * 100).round() : 0;
        final absentPct = totalCount > 0 ? ((absentCount / totalCount) * 100).round() : 0;

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(attendanceProvider.notifier).loadAttendance();
            await ref.read(employeesProvider.notifier).loadEmployees();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Date Bar & Overview Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Column(
                    children: [
                      // Date Selector Row
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _shiftDate(-1),
                            icon: const Icon(Icons.chevron_left, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.darkBorder,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            tooltip: 'Previous Day',
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.darkBorder,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_month, color: AppTheme.primary, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _shiftDate(1),
                            icon: const Icon(Icons.chevron_right, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.darkBorder,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            tooltip: 'Next Day',
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final today = AppDateUtils.todayKey();
                              ref.read(selectedDateProvider.notifier).state = today;
                              final now = DateTime.now();
                              ref.read(selectedYearProvider.notifier).state = now.year;
                              ref.read(selectedMonthProvider.notifier).state = now.month;
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.darkBorder,
                              foregroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            child: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Quick 1-Click Batch Mark Actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final ids = activeEmployees.map((e) => e.id).toList();
                                ref.read(attendanceProvider.notifier).batchMark(
                                      selectedDate,
                                      ids,
                                      AttendanceStatus.present,
                                    );
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: const Text('Mark All Present'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final ids = activeEmployees.map((e) => e.id).toList();
                                ref.read(attendanceProvider.notifier).batchMark(
                                      selectedDate,
                                      ids,
                                      AttendanceStatus.absent,
                                    );
                              },
                              icon: const Icon(Icons.cancel_outlined, size: 16),
                              label: const Text('Mark All Absent'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.danger,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          if (unmarkedCount < totalCount) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                ref.read(attendanceProvider.notifier).clearDate(selectedDate);
                              },
                              icon: const Icon(Icons.refresh, color: AppTheme.textMuted, size: 18),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.darkBorder,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              tooltip: 'Reset marks for this date',
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: AppTheme.darkBorder),
                      const SizedBox(height: 12),

                      // Live Counters Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildDarkCounterCard(
                              label: 'Total Workforce',
                              value: '$totalCount',
                              subtitle: 'Active staff',
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDarkCounterCard(
                              label: 'PRESENT [P]',
                              value: '$presentCount',
                              subtitle: '$presentPct%',
                              color: const Color(0xFF34D399),
                              bgColor: const Color(0xFF064E3B).withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDarkCounterCard(
                              label: 'ABSENT [A]',
                              value: '$absentCount',
                              subtitle: '$absentPct%',
                              color: const Color(0xFFF87171),
                              bgColor: const Color(0xFF881337).withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDarkCounterCard(
                              label: 'Not Marked',
                              value: '$unmarkedCount',
                              subtitle: '$driversCount Drv · $staffCount Stf',
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Category Filter Strip
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Workforce ($totalCount)', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Drivers & Trucks ($driversCount)', 'driver', icon: Icons.local_shipping),
                      const SizedBox(width: 8),
                      _buildFilterChip('Staff & Roles ($staffCount)', 'staff', icon: Icons.people),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search driver, vehicle or role...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),

                const SizedBox(height: 16),

                // Attendance Cards List
                if (filteredEmployees.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.search_off, size: 48, color: AppTheme.textMuted),
                        SizedBox(height: 10),
                        Text(
                          'No matching employees found',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Try changing the search filter',
                          style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredEmployees.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final emp = filteredEmployees[index];
                      final currentStatus = todayRecord[emp.id];
                      final isPresent = currentStatus == AttendanceStatus.present;
                      final isAbsent = currentStatus == AttendanceStatus.absent;
                      final isDriver = emp.type == EmployeeType.driver;

                      final standardDays = settings?.standardMonthDays ?? 30;
                      final dailyWage = emp.salaryType == SalaryType.daily
                          ? emp.salary
                          : (emp.salary / standardDays).roundToDouble();

                      Color cardBorderColor = AppTheme.border;
                      Color cardBgColor = Colors.white;
                      if (isPresent) {
                        cardBorderColor = const Color(0xFF6EE7B7);
                        cardBgColor = const Color(0xFFECFDF5);
                      } else if (isAbsent) {
                        cardBorderColor = const Color(0xFFFDA4AF);
                        cardBgColor = const Color(0xFFFFF1F2);
                      }

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorderColor, width: isPresent || isAbsent ? 1.5 : 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Worker Header
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isDriver
                                        ? const Color(0xFFFEF3C7)
                                        : const Color(0xFFDBEAFE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isDriver ? Icons.local_shipping : Icons.people,
                                    color: isDriver ? AppTheme.primaryDark : const Color(0xFF2563EB),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              emp.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 15,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isDriver
                                                  ? const Color(0xFFFEF3C7)
                                                  : const Color(0xFFF4F4F5),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isDriver
                                                    ? const Color(0xFFFDE68A)
                                                    : AppTheme.border,
                                              ),
                                            ),
                                            child: Text(
                                              isDriver ? 'DRIVER' : 'STAFF',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: isDriver ? const Color(0xFF92400E) : AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        emp.description,
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

                            // Driver Vehicle Banner
                            if (isDriver && emp.vehicleName != null && emp.vehicleName!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Assigned Vehicle: ',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF92400E),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '🚛 ${emp.vehicleName}',
                                        style: const TextStyle(fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Salary info row
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Salary: ${CurrencyUtils.format(emp.salary, settings?.currency ?? '₹')}${emp.salaryType == SalaryType.monthly ? '/mo' : '/day'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const Text('·', style: TextStyle(color: AppTheme.textMuted)),
                                Text(
                                  'Rate: ~${CurrencyUtils.format(dailyWage, settings?.currency ?? '₹')}/day',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textTertiary,
                                  ),
                                ),
                                if (emp.phone.isNotEmpty && emp.phone != 'N/A') ...[
                                  const Text('·', style: TextStyle(color: AppTheme.textMuted)),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 11, color: AppTheme.textTertiary),
                                      const SizedBox(width: 2),
                                      Text(
                                        emp.phone,
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 14),

                            // ONLY PRESENT AND ABSENT - Big Two-Button Selector
                            Row(
                              children: [
                                // PRESENT BUTTON
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      ref.read(attendanceProvider.notifier).markAttendance(
                                            selectedDate,
                                            emp.id,
                                            AttendanceStatus.present,
                                          );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isPresent
                                            ? AppTheme.success
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isPresent ? AppTheme.success : AppTheme.border,
                                          width: isPresent ? 2 : 1,
                                        ),
                                        boxShadow: isPresent
                                            ? [
                                                BoxShadow(
                                                  color: AppTheme.success.withValues(alpha: 0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 16,
                                            color: isPresent ? Colors.white : AppTheme.success,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'PRESENT [P]',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12,
                                              letterSpacing: 0.5,
                                              color: isPresent ? Colors.white : AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // ABSENT BUTTON
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      ref.read(attendanceProvider.notifier).markAttendance(
                                            selectedDate,
                                            emp.id,
                                            AttendanceStatus.absent,
                                          );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isAbsent ? AppTheme.danger : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isAbsent ? AppTheme.danger : AppTheme.border,
                                          width: isAbsent ? 2 : 1,
                                        ),
                                        boxShadow: isAbsent
                                            ? [
                                                BoxShadow(
                                                  color: AppTheme.danger.withValues(alpha: 0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.cancel,
                                            size: 16,
                                            color: isAbsent ? Colors.white : AppTheme.danger,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'ABSENT [A]',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12,
                                              letterSpacing: 0.5,
                                              color: isAbsent ? Colors.white : AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 20),

                // Quick Add Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Need to add a new driver truck or transport staff member to attendance?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _openAddModal(EmployeeType.driver),
                            icon: const Icon(Icons.local_shipping, size: 16),
                            label: const Text('+ Add Driver'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: AppTheme.dark,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () => _openAddModal(EmployeeType.staff),
                            icon: const Icon(Icons.people, size: 16),
                            label: const Text('+ Add Staff'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.darkSurface,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDarkCounterCard({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    Color? bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor ?? AppTheme.darkBorder,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {IconData? icon}) {
    final isSelected = _filterType == value;
    return InkWell(
      onTap: () => setState(() => _filterType = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.dark : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppTheme.dark : AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
