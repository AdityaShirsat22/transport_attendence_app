# FleetTrack — Flutter Commercial Attendance & Salary Management

A native Flutter Android application ported from the FleetTrack web platform, engineered specifically for commercial fleet logistics, heavy transport operators, and warehouse operations.

Built for **Admin use only**, ensuring streamlined management of drivers, trucks, warehouse operations staff, daily attendance, monthly registers, and wage payroll calculation.

---

## 🚚 Key Features & Module Inventory

### 1. Daily Attendance Marking (`/daily`)
- **Interactive Date Bar**: Navigate by day (`<` / `>`), tap to open the full calendar picker, or click **Today** to jump to the current date.
- **1-Click Batch Actions**: Fast single-tap **Mark All Present** and **Mark All Absent** buttons, plus a **Reset** button to clear marks for the selected date.
- **Live Fleet Counters**: Real-time workforce metrics showing total drivers and staff, Present [P] count with percentage, Absent [A] count with percentage, and unmarked counts.
- **Category Filter & Search**: Filter workforce by *All*, *Drivers & Trucks*, or *Staff & Roles*. Real-time search across driver names, vehicle registrations, and job roles.
- **Only Present & Absent Protocol**: High-contrast, large dual-button selector:
  - **PRESENT [P]** (Emerald Green)
  - **ABSENT [A]** (Rose Red)
  - Tap active status again to un-mark (toggle behavior).
- **Assigned Vehicle Highlights**: Drivers prominently display their truck model and registration plate (e.g., `Tata Signa 4825.T Heavy Truck (MH 12 QX 4521)`).

### 2. Monthly Attendance Register (`/monthly`)
- **Month Navigation**: Cycle months with accurate leap year and calendar days calculation.
- **Horizontal Matrix Grid**: Employee × Day matrix showing daily presence across all calendar days.
- **Cell Cycling**: Tap any day cell directly to cycle between `Unmarked [-]` ➔ `Present [P]` ➔ `Absent [A]` ➔ `Unmarked [-]`.
- **Live Monthly Totals**: Cumulative Present [P] and Absent [A] counts per employee with dynamic recalculation of earned wages.
- **CSV Data Export**: Export the full monthly attendance matrix to CSV via standard Android share/save dialog.
- **Print Register**: Direct printable landscape PDF register generation using the `printing` package.

### 3. Salary & Payroll Management (`/payroll`)
- **Financial Metric Cards**:
  - **Net Monthly Payout (Earned)**: Calculated strictly from Present days.
  - **Total Driver Wages**: Segregated commercial driver payout.
  - **Total Staff Wages**: Warehouse & office logistics staff payout.
  - **Absent Days Deduction**: Company savings on unworked shifts.
- **Detailed Wage Breakdown Table**: Lists base salary, calculated daily rate, days present, days absent, and net payable amount.
- **Printable Payroll Statement**: Full-sheet PDF report ready for dispatch to company finance or accounting.

### 4. Fleet Drivers & Vehicles Management (`/drivers`)
- Paired driver and commercial vehicle management with registration plates and cargo routes.
- Individual custom salary rates (Monthly fixed or Per-day wage).
- Calculated daily rate preview.
- Add, edit, and delete with a 4-second confirmation safeguard against accidental deletions.

### 5. Transport Operations & Staff Management (`/staff`)
- Management of non-driving staff: Yard supervisors, fleet mechanics, bilty/waybill accountants, fastag/diesel coordinators, and security crews.
- Individual wage rates and job descriptions.
- Add, edit, and delete with safety confirmation.

### 6. Printable Salary Slip / Voucher Dialog (`SalarySlipDialog` & `SalarySlipPdfGenerator`)
- Pixel-perfect formal salary payout voucher generated in PDF.
- Company branding: Name, tagline, transport hub city, and telephone.
- Employee profile & category breakdown.
- Crucial commercial transport vehicle details for drivers.
- Attendance summary: Total days in month, Days Present [P], Days Absent [A].
- Formal calculation table: Base rate, daily rate, earned attendance, and **NET PAYABLE SALARY**.
- Official signature boxes: Driver/Employee Signature and Authorized Transport Manager Sign & Seal.
- Direct on-screen preview with instant thermal/office printer dispatch via `Printing.layoutPdf`.

### 7. Transport Business Settings (`/settings`)
- Configurable company name, tagline, office city, phone number, currency symbol (`₹`), and month days divisor (20–31 days, default 30).
- **Data Backup & Migration**:
  - **Export JSON**: Complete backup file containing company settings, workforce records, and historical attendance logs.
  - **Import JSON**: One-click restore with format validation.
- **Reset to Sample Transport Data**: Quickly restore the realistic 12-worker commercial fleet dataset.

### 8. Admin Authentication (`/login`)
- Dedicated administrative access.
- Supabase Auth integration (email + password).
- Direct Admin Demo Access fallback for rapid offline testing.

---

## 🧮 Salary Calculation Formulas

### Monthly Fixed Wage Mode
$$\text{divisor} = \begin{cases} \text{standardMonthDays} & \text{if } \text{standardMonthDays} > 0 \\ \text{daysInMonth} & \text{otherwise} \end{cases}$$

$$\text{dailyRate} = \frac{\text{round}((\text{salary} / \text{divisor}) \times 100)}{100}$$

$$\text{payableSalary} = \text{round}(\text{dailyRate} \times \text{presentDays})$$

### Daily Wage Mode
$$\text{dailyRate} = \text{salary}$$

$$\text{payableSalary} = \text{round}(\text{salary} \times \text{presentDays})$$

> **Important Rule**: Only **Present** days count toward earned wages. Unmarked days do not penalize until or unless marked Absent, and absent days receive 0 wages.

---

## 🗄️ Supabase PostgreSQL Backend Setup

SQL migration files are located in `fleettrack/supabase/migrations/`:

1. `001_initial_schema.sql`:
   - Creates `company_settings`, `employees`, and `attendance_records` tables.
   - Enforces unique `(employee_id, date)` constraints.
   - Sets up Row Level Security (RLS) policies for authenticated administrator access.
   - Adds automatic `updated_at` triggers.
2. `002_seed_data.sql`:
   - Seeds the default company profile and 12 initial transport workers (6 drivers with commercial vehicles, 6 logistics staff).

### Connecting to Your Supabase Project

1. Create a Supabase project at [https://supabase.com](https://supabase.com).
2. Open **SQL Editor** in the Supabase Dashboard and run `001_initial_schema.sql` (or `003_fix_rls_and_confirm_admin.sql`).
3. Copy the configuration template:
   ```bash
   cp lib/core/config/supabase_config.example.dart lib/core/config/supabase_config.dart
   ```
4. Insert your **Project URL** and **anon / public key** into `lib/core/config/supabase_config.dart`:
   - Found in Supabase Dashboard > **Settings > API**.

> **Security Note**: `lib/core/config/supabase_config.dart` is listed in `.gitignore` to prevent credentials and private API keys from ever being committed or exposed on GitHub.

---

## 🚀 Running and Testing

```bash
cd fleettrack

# Fetch dependencies
flutter pub get

# Check static analysis (0 warnings, 0 errors)
flutter analyze

# Run all unit and widget tests
flutter test

# Run on an Android device or emulator
flutter run
```
