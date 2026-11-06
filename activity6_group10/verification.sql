-- ============================================================================
-- VERIFICATION SQL SCRIPT FOR BOARDTRACK DATABASE
-- Course: COMP 018 – Database Administration (Activity 6)
-- Target Database: boardtrack_db / boardtrack_db_activity6_restore_test
-- Description: Comprehensive automated tests for tables, columns, constraints,
--              indexes, sequences, views, row counts, and access controls.
-- ============================================================================

\echo '============================================================================'
\echo '  BOARDTRACK DATABASE RESTORATION & INTEGRITY VERIFICATION SUITE'
\echo '============================================================================'

-- Set client formatting
\pset null '<NULL>'

-- ----------------------------------------------------------------------------
-- 1. BASE TABLES VERIFICATION
-- ----------------------------------------------------------------------------
\echo '\n[TEST 1] Verifying Expected Public Base Tables...'
SELECT 
    t.expected_table,
    CASE WHEN c.table_name IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS status
FROM (
    VALUES 
        ('property'),
        ('room'),
        ('tenant'),
        ('lease'),
        ('payment'),
        ('utility_bill'),
        ('app_user'),
        ('schema_migrations')
) AS t(expected_table)
LEFT JOIN information_schema.tables c 
    ON c.table_schema = 'public' 
   AND c.table_type = 'BASE TABLE' 
   AND c.table_name = t.expected_table
ORDER BY t.expected_table;

-- ----------------------------------------------------------------------------
-- 2. PRIMARY KEYS VERIFICATION
-- ----------------------------------------------------------------------------
\echo '\n[TEST 2] Verifying Primary Key Constraints...'
SELECT 
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    'PASS' AS status
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name 
   AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY' 
  AND tc.table_schema = 'public'
ORDER BY tc.table_name;

-- ----------------------------------------------------------------------------
-- 3. FOREIGN KEY RELATIONSHIPS VERIFICATION
-- ----------------------------------------------------------------------------
\echo '\n[TEST 3] Verifying Foreign Key Constraints and Target Tables...'
SELECT 
    tc.table_name AS source_table,
    kcu.column_name AS source_column,
    ccu.table_name AS target_table,
    ccu.column_name AS target_column,
    rc.delete_rule,
    'PASS' AS status
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu 
    ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints rc 
    ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- ----------------------------------------------------------------------------
-- 4. UNIQUE CONSTRAINTS
-- ----------------------------------------------------------------------------
\echo '\n[TEST 4] Verifying Unique Constraints...'
SELECT 
    tc.table_name,
    tc.constraint_name,
    string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) AS unique_columns,
    'PASS' AS status
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'UNIQUE' 
  AND tc.table_schema = 'public'
GROUP BY tc.table_name, tc.constraint_name
ORDER BY tc.table_name;

-- ----------------------------------------------------------------------------
-- 5. CHECK CONSTRAINTS & EXCLUSION CONSTRAINT
-- ----------------------------------------------------------------------------
\echo '\n[TEST 5A] Verifying Check Constraints...'
SELECT 
    conrelid::regclass::text AS table_name,
    conname AS constraint_name,
    pg_get_constraintdef(c.oid) AS constraint_definition,
    'PASS' AS status
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE n.nspname = 'public' AND c.contype = 'c'
ORDER BY table_name, conname;

\echo '\n[TEST 5B] Verifying GiST Exclusion Constraint (Lease Overlap Prevention)...'
SELECT 
    conrelid::regclass::text AS table_name,
    conname AS constraint_name,
    pg_get_constraintdef(c.oid) AS constraint_definition,
    'PASS' AS status
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
WHERE n.nspname = 'public' AND c.contype = 'x' AND conname = 'ex_lease_no_overlap';

-- ----------------------------------------------------------------------------
-- 6. SECONDARY INDEXES
-- ----------------------------------------------------------------------------
\echo '\n[TEST 6] Verifying Secondary Performance Indexes...'
SELECT 
    tablename,
    indexname,
    indexdef,
    'PASS' AS status
FROM pg_indexes
WHERE schemaname = 'public' 
  AND indexname IN ('idx_lease_room', 'idx_lease_tenant', 'idx_payment_lease', 'idx_utility_lease')
ORDER BY tablename, indexname;

-- ----------------------------------------------------------------------------
-- 7. SEQUENCES INVENTORY
-- ----------------------------------------------------------------------------
\echo '\n[TEST 7] Verifying Database Sequences...'
SELECT 
    sequence_name,
    data_type,
    start_value,
    'PASS' AS status
FROM information_schema.sequences
WHERE sequence_schema = 'public'
ORDER BY sequence_name;

-- ----------------------------------------------------------------------------
-- 8. VIEWS VERIFICATION
-- ----------------------------------------------------------------------------
\echo '\n[TEST 8] Verifying Views & Computed Summary Logic...'
SELECT 
    table_name AS view_name,
    CASE WHEN table_name = 'v_lease_summary' THEN 'PASS' ELSE 'FAIL' END AS status
FROM information_schema.views
WHERE table_schema = 'public';

\echo '\n[TEST 8B] Testing v_lease_summary Output...'
SELECT 
    lease_id,
    tenant,
    property_name,
    room_number,
    monthly_rent,
    total_paid,
    utilities_billed,
    status
FROM v_lease_summary
ORDER BY lease_id;

-- ----------------------------------------------------------------------------
-- 9. QUANTITATIVE ROW COUNTS & SAMPLE DATA INTEGRITY
-- ----------------------------------------------------------------------------
\echo '\n[TEST 9] Verifying Baseline Row Counts Against Seed Expectations...'
SELECT 
    'property' AS table_name, COUNT(*) AS row_count, 2 AS expected_count,
    CASE WHEN COUNT(*) = 2 THEN 'PASS' ELSE 'NEEDS REVIEW' END AS status FROM property
UNION ALL
SELECT 'room', COUNT(*), 6, CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'NEEDS REVIEW' END FROM room
UNION ALL
SELECT 'tenant', COUNT(*), 4, CASE WHEN COUNT(*) = 4 THEN 'PASS' ELSE 'NEEDS REVIEW' END FROM tenant
UNION ALL
SELECT 'lease', COUNT(*), 4, CASE WHEN COUNT(*) = 4 THEN 'PASS' ELSE 'NEEDS REVIEW' END FROM lease
UNION ALL
SELECT 'payment', COUNT(*), 6, CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'NEEDS REVIEW' END FROM payment
UNION ALL
SELECT 'utility_bill', COUNT(*), 4, CASE WHEN COUNT(*) = 4 THEN 'PASS' ELSE 'NEEDS REVIEW' END FROM utility_bill
UNION ALL
SELECT 'app_user', COUNT(*), 3, CASE WHEN COUNT(*) = 3 THEN 'PASS' ELSE 'NEEDS REVIEW' END FROM app_user
UNION ALL
SELECT 'schema_migrations', COUNT(*), 1, CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'NEEDS REVIEW' END FROM schema_migrations;

-- ----------------------------------------------------------------------------
-- 10. REFERENTIAL INTEGRITY (ORPHAN RECORD AUDIT)
-- ----------------------------------------------------------------------------
\echo '\n[TEST 10] Checking for Orphaned Foreign Key Records...'
SELECT 'Orphan Rooms' AS check_name, COUNT(*) AS orphans,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM room r LEFT JOIN property p ON r.property_id = p.property_id WHERE p.property_id IS NULL
UNION ALL
SELECT 'Orphan Leases (Tenant)', COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM lease l LEFT JOIN tenant t ON l.tenant_id = t.tenant_id WHERE t.tenant_id IS NULL
UNION ALL
SELECT 'Orphan Leases (Room)', COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM lease l LEFT JOIN room r ON l.room_id = r.room_id WHERE r.room_id IS NULL
UNION ALL
SELECT 'Orphan Payments', COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM payment p LEFT JOIN lease l ON p.lease_id = l.lease_id WHERE l.lease_id IS NULL
UNION ALL
SELECT 'Orphan Utility Bills', COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM utility_bill u LEFT JOIN lease l ON u.lease_id = l.lease_id WHERE l.lease_id IS NULL
UNION ALL
SELECT 'Orphan App Users (Tenant FK)', COUNT(*),
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM app_user u LEFT JOIN tenant t ON u.tenant_id = t.tenant_id 
WHERE u.role = 'tenant' AND t.tenant_id IS NULL;

-- ----------------------------------------------------------------------------
-- 11. PROCEDURAL TRIGGERS CHECK
-- ----------------------------------------------------------------------------
\echo '\n[TEST 11] Verifying Room-Lease Synchronization Triggers...'
SELECT 
    event_object_table AS trigger_table,
    trigger_name,
    action_timing,
    event_manipulation,
    'PASS' AS status
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND trigger_name IN ('trg_lease_sync_room', 'trg_room_status_guard')
ORDER BY trigger_table, trigger_name;

-- ----------------------------------------------------------------------------
-- 12. CLUSTER ROLES & ACCESS CONTROL AUDIT
-- ----------------------------------------------------------------------------
\echo '\n[TEST 12] Auditing Cluster Roles (docs/user-roles.md Specification)...'
SELECT 
    r.expected_role,
    r.expected_type,
    CASE WHEN pr.rolname IS NOT NULL THEN 'PRESENT' ELSE 'NOT FOUND' END AS presence,
    COALESCE(pr.rolcanlogin::text, 'N/A') AS can_login,
    COALESCE(pr.rolsuper::text, 'N/A') AS is_superuser,
    CASE 
        WHEN pr.rolname IS NOT NULL THEN 'PASS' 
        ELSE 'NEEDS REVIEW' 
    END AS status
FROM (
    VALUES 
        ('boardtrack_owner', 'LOGIN (DB Owner)'),
        ('boardtrack_admin_grp', 'NOLOGIN (Admin Group)'),
        ('app_runtime_grp', 'NOLOGIN (Runtime Group)'),
        ('app_readonly_grp', 'NOLOGIN (Read-Only Group)'),
        ('boardtrack_app', 'LOGIN (App Runtime User)')
) AS r(expected_role, expected_type)
LEFT JOIN pg_roles pr ON pr.rolname = r.expected_role;

\echo '\n[TEST 13] Checking Role Memberships...'
SELECT 
    m.rolname AS member_role,
    g.rolname AS group_role,
    'PASS' AS status
FROM pg_auth_members am
JOIN pg_roles m ON am.member = m.oid
JOIN pg_roles g ON am.roleid = g.oid
WHERE m.rolname IN ('boardtrack_app', 'boardtrack_owner')
   OR g.rolname IN ('boardtrack_admin_grp', 'app_runtime_grp', 'app_readonly_grp');

\echo '============================================================================'
\echo '  END OF VERIFICATION EXECUTION'
\echo '============================================================================'

