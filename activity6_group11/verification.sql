-- ============================================================================
-- COMP 018 Activity 6: Database Verification Suite
-- Project: BoardTrack — Boarding House & Rental Management System
-- Target Database: boardtrack_db (or restored test database)
-- Script: verification.sql
-- Description: Comprehensive SQL audit suite validating database objects,
--              schema integrity, constraints, triggers, data, and access controls.
-- ============================================================================

\echo '============================================================================'
\echo ' BoardTrack Database Verification Suite (COMP 018 Activity 6)'
\echo '============================================================================'

-- ============================================================================
-- TEST 1: Relational Table Inventory
-- Verifies presence of all 7 business tables plus migration tracking table
-- ============================================================================
\echo '\n--- TEST 1: Table Inventory (Expected: 8 tables in public schema) ---'
SELECT table_name,
       table_type
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;


-- ============================================================================
-- TEST 2: Column Names, Data Types, and Nullability
-- ============================================================================
\echo '\n--- TEST 2: Column Definitions and Data Types ---'
SELECT table_name,
       ordinal_position,
       column_name,
       data_type,
       character_maximum_length,
       numeric_precision,
       numeric_scale,
       is_nullable,
       column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('property', 'room', 'tenant', 'lease', 'payment', 'utility_bill', 'app_user', 'schema_migrations')
ORDER BY table_name, ordinal_position;


-- ============================================================================
-- TEST 3: Primary Key Constraints
-- ============================================================================
\echo '\n--- TEST 3: Primary Key Constraints ---'
SELECT tc.table_name,
       tc.constraint_name,
       kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
WHERE tc.table_schema = 'public'
  AND tc.constraint_type = 'PRIMARY KEY'
ORDER BY tc.table_name;


-- ============================================================================
-- TEST 4: Foreign Key Constraints and Referential Integrity
-- ============================================================================
\echo '\n--- TEST 4: Foreign Key Constraints and Target Tables ---'
SELECT tc.table_name AS source_table,
       kcu.column_name AS source_column,
       tc.constraint_name,
       ccu.table_name AS referenced_table,
       ccu.column_name AS referenced_column,
       rc.delete_rule
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.referential_constraints rc
  ON tc.constraint_name = rc.constraint_name
JOIN information_schema.constraint_column_usage ccu
  ON rc.unique_constraint_name = ccu.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY source_table, source_column;


-- ============================================================================
-- TEST 5: Unique Constraints
-- ============================================================================
\echo '\n--- TEST 5: Unique Constraints ---'
SELECT tc.table_name,
       tc.constraint_name,
       kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.constraint_type = 'UNIQUE'
ORDER BY tc.table_name, kcu.ordinal_position;


-- ============================================================================
-- TEST 6: Check Constraints and Exclusion Constraints
-- ============================================================================
\echo '\n--- TEST 6: Check Constraints & Exclusion Constraints ---'
SELECT conrelid::regclass AS table_name,
       conname AS constraint_name,
       contype AS constraint_type,
       pg_get_constraintdef(c.oid) AS constraint_definition
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE n.nspname = 'public'
  AND contype IN ('c', 'x')
ORDER BY table_name, conname;


-- ============================================================================
-- TEST 7: Secondary and Constraint Indexes
-- ============================================================================
\echo '\n--- TEST 7: Index Inventory (B-tree and GiST) ---'
SELECT tablename,
       indexname,
       indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;


-- ============================================================================
-- TEST 8: Sequences Inventory
-- ============================================================================
\echo '\n--- TEST 8: Sequences Inventory ---'
SELECT sequence_name,
       data_type,
       start_value,
       minimum_value,
       maximum_value
FROM information_schema.sequences
WHERE sequence_schema = 'public'
ORDER BY sequence_name;


-- ============================================================================
-- TEST 9: View Inventory and Accessibility
-- ============================================================================
\echo '\n--- TEST 9: Views Inventory (v_lease_summary) ---'
SELECT table_name AS view_name,
       view_definition
FROM information_schema.views
WHERE table_schema = 'public';

\echo '\n--- TEST 9.1: Probe View Execution ---'
SELECT * FROM v_lease_summary LIMIT 5;


-- ============================================================================
-- TEST 10: Trigger Functions and Triggers
-- ============================================================================
\echo '\n--- TEST 10: Triggers and Associated Functions ---'
SELECT event_object_table AS target_table,
       trigger_name,
       event_manipulation AS event,
       action_timing AS timing,
       action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY target_table, trigger_name;


-- ============================================================================
-- TEST 11: Table Row Counts and Baseline Verification
-- ============================================================================
\echo '\n--- TEST 11: Table Row Counts ---'
SELECT 'property' AS table_name, count(*) AS row_count FROM property
UNION ALL
SELECT 'room', count(*) FROM room
UNION ALL
SELECT 'tenant', count(*) FROM tenant
UNION ALL
SELECT 'lease', count(*) FROM lease
UNION ALL
SELECT 'payment', count(*) FROM payment
UNION ALL
SELECT 'utility_bill', count(*) FROM utility_bill
UNION ALL
SELECT 'app_user', count(*) FROM app_user
UNION ALL
SELECT 'schema_migrations', count(*) FROM schema_migrations;


-- ============================================================================
-- TEST 12: Business Relational Integrity (Multi-Table JOIN)
-- ============================================================================
\echo '\n--- TEST 12: Multi-Table Relational JOIN Verification ---'
SELECT p.property_name,
       r.room_number,
       t.full_name AS tenant_name,
       l.start_date,
       l.end_date,
       l.monthly_rent,
       l.status AS lease_status,
       count(pm.payment_id) AS total_payments,
       coalesce(sum(pm.amount), 0.00) AS total_paid
FROM property p
JOIN room r ON r.property_id = p.property_id
JOIN lease l ON l.room_id = r.room_id
JOIN tenant t ON t.tenant_id = l.tenant_id
LEFT JOIN payment pm ON pm.lease_id = l.lease_id AND pm.status = 'COMPLETED'
GROUP BY p.property_name, r.room_number, t.full_name, l.start_date, l.end_date, l.monthly_rent, l.status
ORDER BY p.property_name, r.room_number;


-- ============================================================================
-- TEST 13: Cluster Roles and Role Attributes
-- ============================================================================
\echo '\n--- TEST 13: Cluster Roles and Attributes ---'
SELECT rolname,
       rolcanlogin,
       rolsuper,
       rolcreatedb,
       rolcreaterole
FROM pg_roles
WHERE rolname IN (
    'boardtrack_owner',
    'boardtrack_admin_grp',
    'app_runtime_grp',
    'app_readonly_grp',
    'boardtrack_app'
)
ORDER BY rolname;


-- ============================================================================
-- TEST 14: Role Memberships
-- ============================================================================
\echo '\n--- TEST 14: Role Memberships ---'
SELECT r.rolname AS member_role,
       g.rolname AS group_role,
       m.admin_option
FROM pg_auth_members m
JOIN pg_roles r ON r.oid = m.member
JOIN pg_roles g ON g.oid = m.roleid
WHERE g.rolname IN ('boardtrack_admin_grp', 'app_runtime_grp', 'app_readonly_grp')
   OR r.rolname IN ('boardtrack_app');


-- ============================================================================
-- TEST 15: Table and View Permissions Granted to Roles
-- ============================================================================
\echo '\n--- TEST 15: Table and View Privileges by Role ---'
SELECT grantee,
       table_schema,
       table_name,
       privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND grantee IN ('boardtrack_admin_grp', 'app_runtime_grp', 'app_readonly_grp', 'boardtrack_app')
ORDER BY grantee, table_name, privilege_type;

\echo '============================================================================'
\echo ' Verification Suite Execution Finished'
\echo '============================================================================'

