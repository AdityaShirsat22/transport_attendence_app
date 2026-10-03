-- Migration 003: Confirm Admin Email and Grant Access to anon & authenticated roles
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor > New query)

-- 1. Auto-confirm the admin email so password login creates a valid Supabase session
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'sandeepgarje9011@gmail.com';

-- 2. Update Row Level Security (RLS) policies to allow both anon and authenticated roles
-- Company Settings
DROP POLICY IF EXISTS "Allow authenticated read company_settings" ON company_settings;
DROP POLICY IF EXISTS "Allow authenticated insert company_settings" ON company_settings;
DROP POLICY IF EXISTS "Allow authenticated update company_settings" ON company_settings;
DROP POLICY IF EXISTS "Allow all read company_settings" ON company_settings;
DROP POLICY IF EXISTS "Allow all insert company_settings" ON company_settings;
DROP POLICY IF EXISTS "Allow all update company_settings" ON company_settings;

CREATE POLICY "Allow all read company_settings" ON company_settings FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow all insert company_settings" ON company_settings FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow all update company_settings" ON company_settings FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);

-- Employees
DROP POLICY IF EXISTS "Allow authenticated read employees" ON employees;
DROP POLICY IF EXISTS "Allow authenticated insert employees" ON employees;
DROP POLICY IF EXISTS "Allow authenticated update employees" ON employees;
DROP POLICY IF EXISTS "Allow authenticated delete employees" ON employees;
DROP POLICY IF EXISTS "Allow all read employees" ON employees;
DROP POLICY IF EXISTS "Allow all insert employees" ON employees;
DROP POLICY IF EXISTS "Allow all update employees" ON employees;
DROP POLICY IF EXISTS "Allow all delete employees" ON employees;

CREATE POLICY "Allow all read employees" ON employees FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow all insert employees" ON employees FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow all update employees" ON employees FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow all delete employees" ON employees FOR DELETE TO anon, authenticated USING (true);

-- Attendance Records
DROP POLICY IF EXISTS "Allow authenticated read attendance_records" ON attendance_records;
DROP POLICY IF EXISTS "Allow authenticated insert attendance_records" ON attendance_records;
DROP POLICY IF EXISTS "Allow authenticated update attendance_records" ON attendance_records;
DROP POLICY IF EXISTS "Allow authenticated delete attendance_records" ON attendance_records;
DROP POLICY IF EXISTS "Allow all read attendance_records" ON attendance_records;
DROP POLICY IF EXISTS "Allow all insert attendance_records" ON attendance_records;
DROP POLICY IF EXISTS "Allow all update attendance_records" ON attendance_records;
DROP POLICY IF EXISTS "Allow all delete attendance_records" ON attendance_records;

CREATE POLICY "Allow all read attendance_records" ON attendance_records FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Allow all insert attendance_records" ON attendance_records FOR INSERT TO anon, authenticated WITH CHECK (true);
CREATE POLICY "Allow all update attendance_records" ON attendance_records FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow all delete attendance_records" ON attendance_records FOR DELETE TO anon, authenticated USING (true);
