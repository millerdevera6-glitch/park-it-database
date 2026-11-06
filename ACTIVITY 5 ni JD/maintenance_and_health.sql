-- ============================================================================
-- ACTIVITY 5: Health Inspection & Routine Maintenance
-- ============================================================================

-- PART A: Health & Activity Inspection
-- 1. Check PostgreSQL version and database name
SELECT version();
SELECT current_database();

-- 2. Check total database size
SELECT pg_size_pretty(pg_database_size(current_database()));

-- 3. Check active connections and sessions
SELECT datname, numbackends
FROM pg_stat_database
WHERE datname = current_database();

-- 4. Check currently running queries and wait events
SELECT pid, usename, state, wait_event_type, wait_event, query_start, query
FROM pg_stat_activity
WHERE datname = current_database()
ORDER BY query_start NULLS LAST;


-- PART C: Routine Maintenance (Run as standalone commands outside transaction blocks)
-- 1. Refresh planner statistics across tables
ANALYZE public.staff;
ANALYZE public.menu_category;
ANALYZE public.menu_item;
ANALYZE public.order_ticket;
ANALYZE public.order_line_item;

-- 2. Run VACUUM with verbose output and analysis on active tables
VACUUM (VERBOSE, ANALYZE) public.order_line_item;
VACUUM (VERBOSE, ANALYZE) public.order_ticket;