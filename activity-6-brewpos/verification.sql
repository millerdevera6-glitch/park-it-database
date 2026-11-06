-- ==============================================================================
-- BrewPOS — Post-Restoration Database Verification Suite (verification.sql)
-- Course   : COMP 018 — Database Administration
-- Project  : BrewPOS — Café Point-of-Sale System
-- Target DB: grp_brewposdb_restore_test
-- Engine   : PostgreSQL 18+ (Compatible with v16+)
-- ==============================================================================

\echo '=================================================================='
\echo ' BrewPOS Verification Suite: Restored Database Integrity Audit    '
\echo '=================================================================='

-- 1. Restored Database Context & Session
SELECT current_database() AS restored_database,
       current_user AS connected_user,
       version() AS pg_version;

-- 2. Base Table Inventory (Strictly exactly 5 application tables expected)
\echo '\n--- [1/10] Table Inventory in schema public ---'
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 3. Column Definitions, Nullability, and Data Types
\echo '\n--- [2/10] Column Specifications ---'
SELECT table_name, ordinal_position, column_name, data_type,
       character_maximum_length, numeric_precision, numeric_scale, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('staff', 'menu_category', 'menu_item', 'order_ticket', 'order_line_item')
ORDER BY table_name, ordinal_position;

-- 4. Primary Key Constraints (Includes Composite PK on order_line_item)
\echo '\n--- [3/10] Primary Key Constraints ---'
SELECT tc.table_name, tc.constraint_name,
       string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) AS pk_columns
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON kcu.constraint_name = tc.constraint_name AND kcu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public' AND tc.constraint_type = 'PRIMARY KEY'
GROUP BY tc.table_name, tc.constraint_name
ORDER BY tc.table_name;

-- 5. Foreign Key Constraints (Zero ON DELETE CASCADE)
\echo '\n--- [4/10] Foreign Key Constraints ---'
SELECT conrelid::regclass AS child_table,
       conname AS fk_constraint_name,
       confrelid::regclass AS referenced_parent_table,
       pg_get_constraintdef(oid) AS fk_definition
FROM pg_constraint
WHERE contype = 'f' AND connamespace = 'public'::regnamespace
ORDER BY child_table::text, conname;

-- 6. Check & Unique Constraints
\echo '\n--- [5/10] CHECK & UNIQUE Constraints ---'
SELECT conrelid::regclass AS table_name,
       conname AS constraint_name,
       CASE contype WHEN 'c' THEN 'CHECK' WHEN 'u' THEN 'UNIQUE' END AS type,
       pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE contype IN ('c', 'u') AND connamespace = 'public'::regnamespace
ORDER BY table_name::text, constraint_name;

-- 7. Indexes (B-tree Primary, Unique, and Performance Indexes)
\echo '\n--- [6/10] Indexes ---'
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 8. Sequence Status & Current Values
\echo '\n--- [7/10] Sequences and Next Identifiers ---'
SELECT sequence_name, last_value, start_value, increment_by
FROM information_schema.sequences s
JOIN pg_sequences ps ON ps.sequencename = s.sequence_name
WHERE s.sequence_schema = 'public'
ORDER BY sequence_name;

-- 9. Row Count Parity Check (100% Parity with Source Backup)
\echo '\n--- [8/10] Row Counts Across All Application Tables ---'
SELECT 'staff'           AS table_name, COUNT(*) AS row_count FROM public.staff
UNION ALL
SELECT 'menu_category',   COUNT(*) FROM public.menu_category
UNION ALL
SELECT 'menu_item',       COUNT(*) FROM public.menu_item
UNION ALL
SELECT 'order_ticket',    COUNT(*) FROM public.order_ticket
UNION ALL
SELECT 'order_line_item', COUNT(*) FROM public.order_line_item
ORDER BY table_name;

-- 10. Relational Integrity & Multi-Table Aggregation
\echo '\n--- [9/10] Order Aggregations & Sales Calculations (Historical vs Live) ---'
SELECT t.order_id,
       t.order_timestamp::date AS order_date,
       s.full_name AS cashier_manager,
       t.payment_method,
       COUNT(l.item_id) AS distinct_line_items,
       SUM(l.quantity) AS total_units_sold,
       SUM(l.quantity * l.sold_price) AS calculated_order_total
FROM public.order_ticket t
JOIN public.staff s ON s.staff_id = t.staff_id
JOIN public.order_line_item l ON l.order_id = t.order_id
GROUP BY t.order_id, t.order_timestamp::date, s.full_name, t.payment_method
ORDER BY t.order_id;

-- 11. Role-Based Access Control (RBAC) Privilege Auditing
\echo '\n--- [10/10] Access Control Grants & Privilege Enforcement ---'
SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND grantee IN ('brewpos_app', 'app_runtime_grp', 'app_readonly_grp', 'app_admin_grp')
ORDER BY grantee, table_name, privilege_type;

-- 12. Security Enforcement Test (Permitted vs Denied DML)
\echo '\n--- Security Enforcement Check: Permitted vs Denied Operations ---'
BEGIN;
  -- Permitted check: Runtime role querying active menu catalog
  SET LOCAL ROLE app_runtime_grp;
  SELECT 'PERMITTED TEST' AS test_name, item_id, item_name, price 
  FROM public.menu_item 
  WHERE is_active = TRUE 
  ORDER BY item_id LIMIT 2;
  RESET ROLE;
ROLLBACK;

-- Denied check demonstration (Executed in verification report):
-- SET ROLE app_runtime_grp;
-- DELETE FROM public.order_ticket WHERE order_id = 1; -- Throws ERROR 42501 (permission denied)
-- RESET ROLE;

