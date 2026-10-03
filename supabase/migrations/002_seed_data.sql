-- FleetTrack Initial Seed Data
-- Insert default company settings and sample transport drivers and staff

-- 1. Seed Company Settings
INSERT INTO company_settings (id, company_name, tagline, phone, city, currency, standard_month_days)
VALUES (
    'default',
    'National Roadlines & Transport Co.',
    'Fleet Logistics, Heavy Cargo & Transport Services',
    '+91 98220 54321',
    'Transport Nagar, Logistics Hub',
    '₹',
    30
) ON CONFLICT (id) DO NOTHING;

-- 2. Seed Employees (6 Drivers + 6 Staff)
INSERT INTO employees (id, name, type, vehicle_name, description, phone, salary, salary_type, joined_date, active)
VALUES
    -- Drivers
    ('emp-drv-01', 'Rajesh Kumar Patil', 'driver', 'Tata Signa 4825.T Heavy Truck (MH 12 QX 4521)', 'Long Haul Multi-Axle Container Driver', '+91 98231 11201', 34000.00, 'monthly', '2024-03-15', true),
    ('emp-drv-02', 'Balwinder Singh Gill', 'driver', 'BharatBenz 2823R Heavy Cargo (PB 10 CZ 8820)', 'Interstate Long Haul Driver (Delhi-Mumbai Corridor)', '+91 98140 22302', 36000.00, 'monthly', '2023-11-01', true),
    ('emp-drv-03', 'Vikram Shinde', 'driver', 'Eicher Pro 3019 6-Wheeler (MH 14 TR 1092)', 'Regional Logistics & FMCG Supply Driver', '+91 98900 33403', 28500.00, 'monthly', '2024-06-10', true),
    ('emp-drv-04', 'Mohammad Tariq Ansari', 'driver', 'Mahindra Bolero Maxi Truck Plus (MH 12 DE 7733)', 'Local City Express Delivery & Parcel Pickup Driver', '+91 97654 44504', 24000.00, 'monthly', '2025-01-20', true),
    ('emp-drv-05', 'Sunil Pawar', 'driver', 'Tata 407 Gold SFC Tempo (MH 20 AB 6610)', 'Hub-to-Hub Warehouse Transfer Driver', '+91 99212 55605', 22500.00, 'monthly', '2025-04-12', true),
    ('emp-drv-06', 'Jagtar Singh Brar', 'driver', 'Ashok Leyland 4220 14-Wheeler Trailer (HR 38 AF 9912)', 'Industrial Steel Coil & Heavy Machinery Driver', '+91 98722 66706', 38000.00, 'monthly', '2023-08-15', true),

    -- Staff
    ('emp-stf-01', 'Suresh Kulkarni', 'staff', NULL, 'Head Fleet Maintenance Mechanic & Engine Specialist', '+91 98229 77807', 31000.00, 'monthly', '2023-02-01', true),
    ('emp-stf-02', 'Deepak Verma', 'staff', NULL, 'Yard Supervisor & Loading/Unloading Dispatch Incharge', '+91 98810 88908', 25000.00, 'monthly', '2024-01-15', true),
    ('emp-stf-03', 'Pooja Deshmukh', 'staff', NULL, 'Waybill, Bilty, E-Way Bill & Billing Accountant', '+91 98501 99019', 27000.00, 'monthly', '2024-05-02', true),
    ('emp-stf-04', 'Rahul Gaikwad', 'staff', NULL, 'Diesel Voucher, Fastag & Fleet Tire Stock Manager', '+91 99702 10120', 21000.00, 'monthly', '2024-09-10', true),
    ('emp-stf-05', 'Anil Jadhav', 'staff', NULL, 'Loading Yard Helper & Fleet Washing Crew', '+91 97633 11221', 16500.00, 'monthly', '2025-02-18', true),
    ('emp-stf-06', 'Santosh More', 'staff', NULL, 'Transport Godown Gatekeeper & Night Security Officer', '+91 98224 12322', 18000.00, 'monthly', '2024-08-01', true)
ON CONFLICT (id) DO NOTHING;
