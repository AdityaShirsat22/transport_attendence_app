-- FleetTrack Database Schema
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor)

-- 1. Create company_settings table
CREATE TABLE IF NOT EXISTS company_settings (
    id TEXT PRIMARY KEY DEFAULT 'default',
    company_name TEXT NOT NULL DEFAULT 'National Roadlines & Transport Co.',
    tagline TEXT DEFAULT 'Fleet Logistics, Heavy Cargo & Transport Services',
    phone TEXT DEFAULT '+91 91374 78077',
    city TEXT DEFAULT 'Transport Nagar, Logistics Hub',
    currency TEXT DEFAULT '₹',
    standard_month_days INTEGER DEFAULT 30,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create employees table
CREATE TABLE IF NOT EXISTS employees (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('driver', 'staff')),
    vehicle_name TEXT,
    description TEXT NOT NULL DEFAULT '',
    phone TEXT DEFAULT '',
    salary NUMERIC(10, 2) NOT NULL DEFAULT 0,
    salary_type TEXT NOT NULL DEFAULT 'monthly' CHECK (salary_type IN ('monthly', 'daily')),
    joined_date DATE NOT NULL DEFAULT CURRENT_DATE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for employees
CREATE INDEX IF NOT EXISTS idx_employees_type ON employees(type);
CREATE INDEX IF NOT EXISTS idx_employees_active ON employees(active);

-- 3. Create attendance_records table
CREATE TABLE IF NOT EXISTS attendance_records (
    id TEXT PRIMARY KEY,
    employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('present', 'absent')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_employee_date UNIQUE (employee_id, date)
);

-- Indexes for attendance_records
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance_records(date);
CREATE INDEX IF NOT EXISTS idx_attendance_employee_id ON attendance_records(employee_id);
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date ON attendance_records(employee_id, date);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE company_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS Policies (Allows both anon and authenticated roles)
-- Company Settings policies
CREATE POLICY "Allow all read company_settings"
    ON company_settings FOR SELECT
    TO anon, authenticated
    USING (true);

CREATE POLICY "Allow all insert company_settings"
    ON company_settings FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

CREATE POLICY "Allow all update company_settings"
    ON company_settings FOR UPDATE
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

-- Employees policies
CREATE POLICY "Allow all read employees"
    ON employees FOR SELECT
    TO anon, authenticated
    USING (true);

CREATE POLICY "Allow all insert employees"
    ON employees FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

CREATE POLICY "Allow all update employees"
    ON employees FOR UPDATE
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow all delete employees"
    ON employees FOR DELETE
    TO anon, authenticated
    USING (true);

-- Attendance Records policies
CREATE POLICY "Allow all read attendance_records"
    ON attendance_records FOR SELECT
    TO anon, authenticated
    USING (true);

CREATE POLICY "Allow all insert attendance_records"
    ON attendance_records FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

CREATE POLICY "Allow all update attendance_records"
    ON attendance_records FOR UPDATE
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Allow all delete attendance_records"
    ON attendance_records FOR DELETE
    TO anon, authenticated
    USING (true);

-- 6. Trigger for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_company_settings_updated_at
    BEFORE UPDATE ON company_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER trg_employees_updated_at
    BEFORE UPDATE ON employees
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER trg_attendance_records_updated_at
    BEFORE UPDATE ON attendance_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
