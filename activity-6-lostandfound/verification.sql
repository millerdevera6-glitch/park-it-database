-- ==============================================================================
-- PUP-SPOT Campus Lost and Found System
-- COMP 018 - Database Administration | Activity 6
-- Script: verification.sql - Comprehensive Restoration & Integrity Verification
-- ==============================================================================

\echo '================================================================='
\echo '  PUP-SPOT DATABASE INTEGRITY & VERIFICATION SUITE (ACTIVITY 6)  '
\echo '================================================================='
\echo ''

-- -----------------------------------------------------------------------------
-- TEST 1: Table Existence (All 8 Core Application Tables)
-- -----------------------------------------------------------------------------
\echo '--- [TEST 1] Verifying Existence of All 8 Tables in public schema ---'
SELECT 
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public' 
  AND table_name IN (
    'categories', 
    'items', 
    'lost_reports', 
    'claims', 
    'potential_matches', 
    'item_images', 
    'lost_report_images', 
    'claim_images'
  )
ORDER BY table_name;

-- -----------------------------------------------------------------------------
-- TEST 2: Primary Keys Verification
-- -----------------------------------------------------------------------------
\echo ''
\echo '--- [TEST 2] Verifying Primary Key Constraints ---'
SELECT 
    tc.table_name, 
    tc.constraint_name, 
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
  ON tc.constraint_name = kcu.constraint_name 
 AND tc.table_schema = kcu.table_schema
WHERE tc.table_schema = 'public' 
  AND tc.constraint_type = 'PRIMARY KEY'
ORDER BY tc.table_name;

-- -----------------------------------------------------------------------------
-- TEST 3: Foreign Key Relationships and Deletion Rules
-- -----------------------------------------------------------------------------
\echo ''
\echo '--- [TEST 3] Verifying Foreign Key Constraints and Cascading Rules ---'
SELECT
    tc.table_name AS source_table,
    kcu.column_name AS source_column,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column,
    rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
 AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
  ON rc.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'public' 
  AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY source_table, source_column;

-- -----------------------------------------------------------------------------
-- TEST 4: Unique Constraints
-- -----------------------------------------------------------------------------
\echo ''
\echo '--- [TEST 4] Verifying Unique Constraints ---'
SELECT 
    table_name, 
    constraint_name, 
    column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
  ON tc.constraint_name = kcu.constraint_name 
 AND tc.table_schema = kcu.table_schema
WHERE tc.table_schema = 'public' 
  AND tc.constraint_type = 'UNIQUE'
ORDER BY table_name, constraint_name;

-- -----------------------------------------------------------------------------
-- TEST 5: Check Constraints (Status & Contact Validations)
-- -----------------------------------------------------------------------------
\echo ''
\echo '--- [TEST 5] Verifying Check Constraints ---'
SELECT 
    tc.table_name, 
    tc.constraint_name, 
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc 
  ON tc.constraint_name = cc.constraint_name 
WHERE tc.table_schema = 'public'
  AND tc.constraint_name NOT LIKE '%_not_null'
ORDER BY tc.table_name, tc.constraint_name;

-- -----------------------------------------------------------------------------
-- TEST 6: Sequences and Current States
-- -----------------------------------------------------------------------------
\echo ''
\echo '--- [TEST 6] Verifying Auto-Increment Sequences ---'
SELECT 
    sequence_name, 
    data_type, 
    start_value, 
    minimum_value, 
    maximum_value
FROM information_schema.sequences
WHERE sequence_schema = 'public'
ORDER BY sequence_name;

-- -----------------------------------------------------------------------------
-- TEST 7: Table Row Counts (Comparison against Backup Manifest)
-- -----------------------------------------------------------------------------
\echo ''
\echo '--- [TEST 7] Table Row Counts vs Expected Manifest ---'
SELECT 'categories' AS table_name, count(*) AS row_count, 11 AS expected_count FROM categories
UNION ALL
SELECT 'items', count(*), 6 FROM items
UNION ALL
SELECT 'lost_reports', count(*), 7 FROM lost_reports
UNION ALL
SELECT 'claims', count(*), 3 FROM claims
UNION ALL
SELECT 'potential_matches', count(*), 6 FROM potential_matches
UNION ALL
SELECT 'item_images', count(*), 0 FROM item_images
UNION ALL
SELECT 'lost_report_images', count(*), 0 FROM lost_report_images
UNION ALL
SELECT 'claim_images', count(*), 0 FROM claim_images
ORDER BY table_name;

-- -----------------------------------------------------------------------------
-- TEST 8: Sample Records & Data Verification
-- -----------------------------------------------------------------------------
\echo ''
\echo '--- [TEST 8.1] Category Reference Data (First 5 records) ---'
SELECT category_id, name FROM categories ORDER BY category_id LIMIT 5;

\echo ''
\echo '--- [TEST 8.2] Found Items & Lifecycle Status ---'
SELECT item_id, category_id, title, status, date_found, location_found FROM items ORDER BY item_id;

\echo ''
\echo '--- [TEST 8.3] Active Lost Reports and Contact Preference ---'
SELECT report_id, report_code, category_id, title, contact_preference, status FROM lost_reports ORDER BY report_id;

\echo ''
\echo '--- [TEST 8.4] Claims and Associated Items ---'
SELECT c.claim_id, c.claim_code, c.item_id, i.title AS item_title, c.full_name, c.status
FROM claims c
LEFT JOIN items i ON c.item_id = i.item_id
ORDER BY c.claim_id;

\echo ''
\echo '--- [TEST 8.5] Potential Matches Scoring and Referential Integrity ---'
SELECT 
    pm.match_id,
    lr.report_code,
    lr.title AS lost_title,
    i.title AS found_title,
    pm.similarity_score
FROM potential_matches pm
JOIN lost_reports lr ON pm.report_id = lr.report_id
JOIN items i ON pm.item_id = i.item_id
ORDER BY pm.match_id;

-- -----------------------------------------------------------------------------
-- TEST 9: Representative Complex Application Query
-- -----------------------------------------------------------------------------
\echo ''
\echo '--- [TEST 9] Representative Application Query: Unclaimed Items Search with Category ---'
SELECT 
    i.item_id,
    i.title,
    c.name AS category_name,
    i.location_found,
    i.date_found,
    i.status
FROM items i
LEFT JOIN categories c ON i.category_id = c.category_id
WHERE i.status = 'unclaimed'
ORDER BY i.date_found DESC, i.item_id DESC;

-- -----------------------------------------------------------------------------
-- TEST 10: Role Privilege Verification Matrix (Non-Destructive)
-- -----------------------------------------------------------------------------
\echo ''
\echo '--- [TEST 10.1] Table Privileges Granted to Application Roles ---'
SELECT 
    grantee, 
    table_name, 
    string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privileges
FROM information_schema.table_privileges
WHERE table_schema = 'public' 
  AND grantee IN ('lostandfound_app', 'lostandfound_public')
GROUP BY grantee, table_name
ORDER BY grantee, table_name;

\echo ''
\echo '--- [TEST 10.2] Role Simulation: Testing lostandfound_public Permitted SELECT ---'
SET ROLE lostandfound_public;
SELECT current_user, count(*) AS categories_accessible FROM categories;
RESET ROLE;

\echo ''
\echo '--- [TEST 10.3] Role Simulation: Testing lostandfound_app Permitted SELECT ---'
SET ROLE lostandfound_app;
SELECT current_user, count(*) AS items_accessible FROM items;
RESET ROLE;

\echo ''
\echo '================================================================='
\echo '          VERIFICATION SUITE EXECUTION COMPLETED                 '
\echo '================================================================='

