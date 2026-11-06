-- BrewPOS Activity 6: Restore Verification
-- Run while connected to grp_brewposdb_restore_test.

-- 1. List application tables.
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- 2. Verify row counts.
SELECT 'staff' AS table_name, COUNT(*) AS row_count FROM public.staff
UNION ALL
SELECT 'menu_category', COUNT(*) FROM public.menu_category
UNION ALL
SELECT 'menu_item', COUNT(*) FROM public.menu_item
UNION ALL
SELECT 'order_ticket', COUNT(*) FROM public.order_ticket
UNION ALL
SELECT 'order_line_item', COUNT(*) FROM public.order_line_item
ORDER BY table_name;

-- 3. Count constraints by type.
SELECT
    CASE contype
        WHEN 'c' THEN 'Check'
        WHEN 'f' THEN 'Foreign key'
        WHEN 'p' THEN 'Primary key'
        WHEN 'u' THEN 'Unique'
        ELSE contype::text
    END AS constraint_type,
    COUNT(*) AS total
FROM pg_constraint
WHERE connamespace = 'public'::regnamespace
GROUP BY contype
ORDER BY constraint_type;

-- 4. Count indexes.
SELECT COUNT(*) AS total_indexes
FROM pg_indexes
WHERE schemaname = 'public';

-- 5. Verify the recovered test record.
-- Expected only in grp_brewposdb_recovery_test after recovery.
SELECT order_id, item_id, quantity, sold_price
FROM public.order_line_item
WHERE order_id = 1 AND item_id = 5;

-- 6. Check the application role's table privileges.
SELECT
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'brewpos_app'
  AND table_schema = 'public'
ORDER BY table_name, privilege_type;