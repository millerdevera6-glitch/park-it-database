-- =============================================================================
-- Activity 5: Database Maintenance and Monitoring Checks
-- Project: BoardTrack — Boarding House & Rental Management System
-- Database Engine: PostgreSQL 18.6 (x86_64-windows)
-- Target Database: boardtrack_db (configured in .env.example & docs/database.md)
-- Inspected Instance: localhost:5432
-- Execution Date: 2026-11-06
-- =============================================================================

-- =============================================================================
-- A. Database Health
-- Inspect database identity, version, storage size, public table counts,
-- sequence counts, active sessions, and verify presence of target database.
-- =============================================================================

-- 1. Identify connected database name, PostgreSQL server version, and storage size
SELECT current_database() AS database_name,
       version() AS server_version,
       pg_size_pretty(pg_database_size(current_database())) AS database_size;

-- 2. Verify existence and storage footprint of the project database (boardtrack_db)
SELECT datname,
       pg_size_pretty(pg_database_size(datname)) AS db_size
FROM pg_database
WHERE datname = 'boardtrack_db';

-- 3. Count public base tables in the connected database
SELECT count(*) AS public_tables
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';

-- 4. Count public sequences in the connected database
SELECT count(*) AS public_sequences
FROM information_schema.sequences
WHERE sequence_schema = 'public';

-- 5. Inspect database connection sessions grouped by state
SELECT state,
       count(*) AS sessions
FROM pg_stat_activity
WHERE datname = current_database()
GROUP BY state;


-- =============================================================================
-- B. Database Activity and User Roles
-- Inspect active sessions and verify cluster roles, login permissions,
-- and administrative privileges (superuser, createdb, createrole).
-- =============================================================================

-- 1. Inspect cluster roles, login capabilities, and administrative privileges
SELECT rolname,
       rolcanlogin,
       rolsuper,
       rolcreatedb,
       rolcreaterole
FROM pg_roles
ORDER BY rolname;

-- 2. Check for project-defined custom roles
SELECT rolname,
       rolsuper,
       rolcreatedb,
       rolcreaterole,
       rolcanlogin
FROM pg_roles
WHERE rolname IN (
    'boardtrack_owner',
    'boardtrack_admin_grp',
    'app_runtime_grp',
    'app_readonly_grp',
    'boardtrack_app'
);

-- 3. Inspect active database sessions and running statements
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
-- Inspect PostgreSQL server logging configuration parameters and active logfile.
-- =============================================================================

-- 1. Inspect logging destination, collector status, directory, and filename pattern
SELECT current_setting('log_destination') AS log_destination,
       current_setting('logging_collector') AS logging_collector,
       current_setting('log_directory') AS log_directory,
       current_setting('log_filename') AS log_filename;

-- 2. Query active log file directly from database engine
SELECT * FROM pg_current_logfile();


-- =============================================================================
-- D. Database Maintenance
-- Inspect optimizer table statistics and execute a safe, targeted ANALYZE
-- operation on the representative application table (public.property).
-- =============================================================================

-- 1. Inspect table statistics (live/dead rows, vacuum and analyze timestamps)
SELECT relname AS table_name,
       n_live_tup AS estimated_live_rows,
       n_dead_tup AS estimated_dead_rows,
       last_vacuum,
       last_autovacuum,
       last_analyze,
       last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY relname;

-- 2. Execute safe statistics update on the project representative table (property)
ANALYZE public.property;


-- =============================================================================
-- E. Query Execution Plan
-- Inspect query planner execution plan and buffer metrics for a safe, read-only
-- SELECT query against the representative application table (public.property).
-- =============================================================================

-- 1. Obtain query execution plan with execution timing and buffer statistics
EXPLAIN (ANALYZE, BUFFERS)
SELECT property_id, property_name, address
FROM public.property
LIMIT 10;

