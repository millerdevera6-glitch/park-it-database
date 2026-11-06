-- ==============================================================================
-- COMP 018 – Database Administration | Activity 6
-- Script: verification.sql
-- Project: HabalGo – Transportation & Booking Management System
-- Purpose: Complete Verification Suite for Restored Test Database
-- Target Database: grp00_habalgodb_activity6_restore_test
-- ==============================================================================

\echo '====================================================='
\echo 'HABALGO DATABASE VERIFICATION SUITE - ACTIVITY 6'
\echo '====================================================='

-- 1. Verify Connected Database and Current User
SELECT current_database() AS verified_database, current_user AS executed_by, version() AS server_version;

-- 2. Verify Schema Existence
SELECT schema_name, schema_owner 
FROM information_schema.schemata 
WHERE schema_name = 'habalgo';

-- 3. Verify Table Inventory (8 Expected Tables)
SELECT table_schema, table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'habalgo' 
ORDER BY table_name;

-- 4. Verify Columns, Data Types, and Nullability
SELECT table_name, column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'habalgo'
ORDER BY table_name, ordinal_position;

-- 5. Verify Primary Key Constraints
SELECT tc.table_name, tc.constraint_name, kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
WHERE tc.table_schema = 'habalgo' AND tc.constraint_type = 'PRIMARY KEY'
ORDER BY tc.table_name;

-- 6. Verify Foreign Key Referential Integrity Constraints
SELECT tc.table_name AS dependent_table, kcu.column_name AS foreign_key_col,
       ccu.table_name AS referenced_table, ccu.column_name AS referenced_col,
       rc.update_rule, rc.delete_rule
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
JOIN information_schema.referential_constraints rc 
    ON tc.constraint_name = rc.constraint_name AND tc.table_schema = rc.constraint_schema
JOIN information_schema.constraint_column_usage ccu 
    ON rc.unique_constraint_name = ccu.constraint_name AND rc.unique_constraint_schema = ccu.constraint_schema
WHERE tc.table_schema = 'habalgo'
ORDER BY tc.table_name;

-- 7. Verify Unique Constraints
SELECT tc.table_name, tc.constraint_name, kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
WHERE tc.table_schema = 'habalgo' AND tc.constraint_type = 'UNIQUE'
ORDER BY tc.table_name;

-- 8. Verify Check Constraints
SELECT conrelid::regclass AS table_name, conname AS constraint_name, pg_get_constraintdef(oid) AS check_expression
FROM pg_constraint
WHERE connamespace = 'habalgo'::regnamespace AND contype = 'c'
ORDER BY table_name;

-- 9. Verify B-Tree Indexes
SELECT tablename, indexname, indexdef 
FROM pg_indexes 
WHERE schemaname = 'habalgo'
ORDER BY tablename, indexname;

-- 10. Verify Sequences
SELECT sequence_name, data_type, start_value, minimum_value, maximum_value 
FROM information_schema.sequences 
WHERE sequence_schema = 'habalgo'
ORDER BY sequence_name;

-- 11. Verify Views and Triggers (Expected 0)
SELECT table_name FROM information_schema.views WHERE table_schema = 'habalgo';
SELECT trigger_name, event_manipulation, event_object_table FROM information_schema.triggers WHERE trigger_schema = 'habalgo';

-- 12. Verify Table Row Counts
SELECT 'customer' AS table_name, count(*) AS total_records FROM habalgo.customer
UNION ALL SELECT 'driver', count(*) FROM habalgo.driver
UNION ALL SELECT 'vehicle', count(*) FROM habalgo.vehicle
UNION ALL SELECT 'driver_vehicle', count(*) FROM habalgo.driver_vehicle
UNION ALL SELECT 'location', count(*) FROM habalgo.location
UNION ALL SELECT 'booking', count(*) FROM habalgo.booking
UNION ALL SELECT 'payment', count(*) FROM habalgo.payment
UNION ALL SELECT 'rating_feedback', count(*) FROM habalgo.rating_feedback;

-- 13. Representative Multi-Table Relational Integrity Query (Simulating api.php Dashboard)
SELECT b.booking_id, c.name AS customer_name, lp.address AS pickup, ld.address AS dropoff,
       d.name AS driver_name, b.booking_status
FROM habalgo.booking b
JOIN habalgo.customer c ON c.customer_id = b.customer_id
JOIN habalgo.location lp ON lp.location_id = b.pickup_location_id
JOIN habalgo.location ld ON ld.location_id = b.dropoff_location_id
LEFT JOIN habalgo.driver d ON d.driver_id = b.driver_id;

-- 14. Access Control Verification: Object Privileges
SELECT grantee, table_name, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_schema = 'habalgo' AND grantee IN ('habalgo_admin', 'habalgo_app', 'habalgo_auditor')
ORDER BY table_name, grantee, privilege_type;

\echo '====================================================='
\echo 'END OF VERIFICATION SUITE'
\echo '====================================================='

