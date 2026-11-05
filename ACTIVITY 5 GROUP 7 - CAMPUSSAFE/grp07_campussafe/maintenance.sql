
-- ============================================================
-- CampusSafe - Group 7
-- Activity 5: Database Maintenance Inspection
-- Database: grp07_campussafedb
-- PostgreSQL: 14.24
--
-- IMPORTANT:
-- The tables are owned by postgres.
-- Maintenance commands are documented but NOT executed here.
-- Run VACUUM/ANALYZE only through an authorized maintenance
-- account or approved procedure.
-- ============================================================

-- 1. Inspect table sizes
SELECT
    schemaname,
    relname AS table_name,
    pg_size_pretty(
        pg_total_relation_size(
            schemaname || '.' || relname
        )
    ) AS total_size
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(
    schemaname || '.' || relname
) DESC;

-- 2. Inspect existing indexes
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 3. Inspect table statistics
SELECT
    relname AS table_name,
    n_live_tup AS estimated_live_rows,
    n_dead_tup AS estimated_dead_rows,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY relname;

-- 4. Inspect table ownership
SELECT
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- 5. Inspect Activity 4 database privileges
SELECT
    rolname,
    has_database_privilege(
        rolname, current_database(), 'CONNECT'
    ) AS can_connect,
    has_database_privilege(
        rolname, current_database(), 'CREATE'
    ) AS can_create,
    has_database_privilege(
        rolname, current_database(), 'TEMP'
    ) AS can_create_temp
FROM pg_roles
WHERE rolname IN (
    'campussafe_app',
    'campussafe_report',
    'campussafe_backup'
)
ORDER BY rolname;

-- 6. Maintenance execution status:
-- VACUUM and ANALYZE were not executed.
-- Reason: all public tables are owned by postgres.
-- Authorization for a separate maintenance account
-- has not been established.
