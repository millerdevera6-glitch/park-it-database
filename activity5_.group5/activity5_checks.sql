-- =============================================================================
-- Activity 5: Database Maintenance and Monitoring Checks
-- Project: PUP-SPOT — Campus Lost and Found (grp05_lostandfound)
-- Database Engine: PostgreSQL 18.x
-- Target Database: grp05_lostandfounddb
-- Execution Date: 2026-11-06
-- =============================================================================

-- =============================================================================
-- A. Database Health
-- Inspect database identity, version, storage footprint, structure counts,
-- and active connections.
-- =============================================================================

-- 1. Identify current database name, PostgreSQL version, and disk size
SELECT current_database() AS database_name,
       version() AS server_version,
       pg_size_pretty(pg_database_size(current_database())) AS database_size;

-- 2. Count existing public base tables (Project defines 8 base tables)
SELECT count(*) AS public_tables
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';

-- 3. Count sequences in public schema (Project defines SERIAL sequences)
SELECT count(*) AS sequence_count
FROM information_schema.sequences
WHERE sequence_schema = 'public';

-- 4. Inspect current database sessions grouped by connection state
SELECT state, count(*) AS sessions
FROM pg_stat_activity
WHERE datname = current_database()
GROUP BY state;


-- =============================================================================
-- B. Database Activity and User Roles
-- Inspect connected sessions and verify custom roles, login rights,
-- and administrative privileges (superuser, createdb, createrole).
-- =============================================================================

-- 1. Inspect existing database roles and privilege flags
SELECT rolname,
       rolcanlogin,
       rolsuper,
       rolcreatedb,
       rolcreaterole
FROM pg_roles
ORDER BY rolname;

-- 2. Inspect active sessions and recent query execution
SELECT pid,
       usename,
       client_addr,
       state,
       backend_start,
       query
FROM pg_stat_activity
WHERE datname = current_database();


-- =============================================================================
-- C. Database Logs
-- Verify PostgreSQL server logging destination, directory, and filename pattern.
-- =============================================================================

-- 1. Query server logging configuration parameters
SELECT current_setting('log_destination') AS log_destination,
       current_setting('logging_collector') AS logging_collector,
       current_setting('log_directory') AS log_directory,
       current_setting('log_filename') AS log_filename;


-- =============================================================================
-- D. Database Maintenance
-- Perform a safe, targeted maintenance operation on a representative table
-- to update query planner statistics, followed by statistics inspection.
-- =============================================================================

-- 1. Update optimizer statistics for representative table 'items'
ANALYZE public.items;

-- 2. Inspect table statistics to confirm last analyze timestamp
SELECT schemaname,
       relname,
       last_analyze,
       last_autoanalyze,
       last_vacuum,
       last_autovacuum
FROM pg_stat_user_tables
WHERE relname = 'items';


-- =============================================================================
-- E. Query Execution Plan
-- Demonstrate query execution plan and planner cost estimation for a representative
-- read-only query on the 'items' table without modifying data.
-- =============================================================================

-- 1. Execution plan for active item catalog query (ordered by date_found)
EXPLAIN (ANALYZE, BUFFERS)
SELECT item_id,
       title,
       description,
       location_found,
       date_found,
       status
FROM public.items
WHERE status = 'unclaimed'
ORDER BY date_found DESC
LIMIT 10;

-- 2. Simple execution plan for base representative scan
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM public.items
LIMIT 10;

