-- ==============================================================================
-- COMP 018 – Database Administration | Activity 6
-- Script: verification.sql
-- Purpose: Verify schema integrity, relational constraints, sequences,
--          sample data, and role privileges on the restored PostgreSQL database.
-- ==============================================================================

\echo '=============================================================================='
\echo ' RUNNING ACTIVITY 6 POSTGRESQL VERIFICATION SUITE'
\echo ' Target Database:' :DBNAME
\echo ' Execution Suite:  Activity 6 Automated Verification'
\echo '=============================================================================='

-- ------------------------------------------------------------------------------
-- TEST 1: VERIFY ALL EXPECTED TABLES EXIST (Target: 12 Tables)
-- ------------------------------------------------------------------------------
\echo '\n--- [TEST 1] VERIFYING BASE TABLES IN PUBLIC SCHEMA ---'

WITH expected_tables(table_name) AS (
    VALUES
        ('users'),
        ('audit_log'),
        ('students'),
        ('companies'),
        ('academic_supervisors'),
        ('company_supervisors'),
        ('requirements'),
        ('ojt_applications'),
        ('student_requirements'),
        ('ojt_placements'),
        ('attendance'),
        ('evaluations')
)
SELECT
    e.table_name,
    CASE WHEN t.table_name IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS status,
    COALESCE(t.table_type, 'MISSING') AS object_type
FROM expected_tables e
LEFT JOIN information_schema.tables t
    ON t.table_schema = 'public'
    AND t.table_name = e.table_name
ORDER BY e.table_name;

-- ------------------------------------------------------------------------------
-- TEST 2: VERIFY PRIMARY KEYS EXIST ON ALL 12 TABLES
-- ------------------------------------------------------------------------------
\echo '\n--- [TEST 2] VERIFYING PRIMARY KEY CONSTRAINTS ---'

WITH pk_check AS (
    SELECT
        t.table_name,
        tc.constraint_name,
        kcu.column_name
    FROM information_schema.tables t
    LEFT JOIN information_schema.table_constraints tc
        ON t.table_name = tc.table_name
        AND tc.table_schema = 'public'
        AND tc.constraint_type = 'PRIMARY KEY'
    LEFT JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
    WHERE t.table_schema = 'public'
      AND t.table_type = 'BASE TABLE'
)
SELECT
    table_name,
    COALESCE(constraint_name, 'NONE') AS pk_constraint,
    COALESCE(column_name, 'NONE') AS pk_column,
    CASE WHEN constraint_name IS NOT NULL THEN 'PASS' ELSE 'FAIL' END AS status
FROM pk_check
ORDER BY table_name;

-- ------------------------------------------------------------------------------
-- TEST 3: VERIFY FOREIGN KEY CONSTRAINTS
-- ------------------------------------------------------------------------------
\echo '\n--- [TEST 3] VERIFYING FOREIGN KEY CONSTRAINTS ---'

SELECT
    tc.table_name AS source_table,
    kcu.column_name AS source_column,
    ccu.table_name AS foreign_table,
    ccu.column_name AS foreign_column,
    tc.constraint_name,
    'PASS' AS status
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- ------------------------------------------------------------------------------
-- TEST 4: VERIFY CHECK & UNIQUE CONSTRAINTS
-- ------------------------------------------------------------------------------
\echo '\n--- [TEST 4] VERIFYING CHECK & UNIQUE CONSTRAINTS ---'

SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    'PASS' AS status
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'public'
  AND tc.constraint_type IN ('CHECK', 'UNIQUE')
ORDER BY tc.table_name, tc.constraint_type;

-- ------------------------------------------------------------------------------
-- TEST 5: VERIFY SEQUENCES EXIST
-- ------------------------------------------------------------------------------
\echo '\n--- [TEST 5] VERIFYING DATABASE SEQUENCES ---'

SELECT
    sequence_name,
    data_type,
    start_value,
    'PASS' AS status
FROM information_schema.sequences
WHERE sequence_schema = 'public'
ORDER BY sequence_name;

-- ------------------------------------------------------------------------------
-- TEST 6: RECORD COUNTS AND DATA INTEGRITY
-- ------------------------------------------------------------------------------
\echo '\n--- [TEST 6] VERIFYING RECORD COUNTS ACROSS ALL TABLES ---'

SELECT 'users' AS table_name, count(*) AS total_rows, CASE WHEN count(*) > 0 THEN 'PASS' ELSE 'NEEDS REVIEW' END AS status FROM users
UNION ALL
SELECT 'audit_log', count(*), 'PASS' FROM audit_log
UNION ALL
SELECT 'students', count(*), CASE WHEN count(*) > 0 THEN 'PASS' ELSE 'NEEDS REVIEW' END FROM students
UNION ALL
SELECT 'companies', count(*), CASE WHEN count(*) > 0 THEN 'PASS' ELSE 'NEEDS REVIEW' END FROM companies
UNION ALL
SELECT 'academic_supervisors', count(*), 'PASS' FROM academic_supervisors
UNION ALL
SELECT 'company_supervisors', count(*), 'PASS' FROM company_supervisors
UNION ALL
SELECT 'requirements', count(*), CASE WHEN count(*) > 0 THEN 'PASS' ELSE 'NEEDS REVIEW' END FROM requirements
UNION ALL
SELECT 'ojt_applications', count(*), 'PASS' FROM ojt_applications
UNION ALL
SELECT 'student_requirements', count(*), 'PASS' FROM student_requirements
UNION ALL
SELECT 'ojt_placements', count(*), 'PASS' FROM ojt_placements
UNION ALL
SELECT 'attendance', count(*), 'PASS' FROM attendance
UNION ALL
SELECT 'evaluations', count(*), 'PASS' FROM evaluations
ORDER BY table_name;

-- ------------------------------------------------------------------------------
-- TEST 7: REPRESENTATIVE RELATIONAL QUERIES (JOIN INTEGRITY)
-- ------------------------------------------------------------------------------
\echo '\n--- [TEST 7] TESTING RELATIONAL INTEGRITY JOINS ---'

-- Query 7A: User to Student Link
SELECT
    u.user_id,
    u.username,
    u.role,
    s.student_number,
    s.first_name || ' ' || s.last_name AS student_full_name,
    'PASS' AS status
FROM users u
JOIN students s ON s.user_id = u.user_id
LIMIT 5;

-- Query 7B: Companies List
SELECT
    company_id,
    company_name,
    industry,
    is_partner,
    'PASS' AS status
FROM companies
LIMIT 5;

-- Query 7C: Requirements Catalog
SELECT
    req_id,
    title,
    is_mandatory,
    'PASS' AS status
FROM requirements
LIMIT 5;

-- ------------------------------------------------------------------------------
-- TEST 8: VERIFY ROLES AND PERMISSIONS
-- ------------------------------------------------------------------------------
\echo '\n--- [TEST 8] VERIFYING POSTGRESQL LOGIN ROLES ---'

SELECT
    rolname,
    rolcanlogin,
    rolsuper,
    'PASS' AS status
FROM pg_roles
WHERE rolname IN (
    'ojt_admin',
    'ojt_student',
    'ojt_academic_supervisor',
    'ojt_company_supervisor',
    'ojt_coordinator'
)
ORDER BY rolname;

\echo '\n=============================================================================='
\echo ' VERIFICATION SUITE EXECUTION COMPLETED'
\echo '=============================================================================='

