-- =============================================================================
-- Activity 5: Database Maintenance and Monitoring Checks
-- Project: Restaurant Online Ordering & Table Reservation System (Binary Sisters)
-- Database: grp_binarysisters_projectdb
-- Engine: PostgreSQL 18.6
-- =============================================================================

\pset pager off

-- -----------------------------------------------------------------------------
-- A. Database Health
-- -----------------------------------------------------------------------------
\echo '=================================================='
\echo 'A. DATABASE HEALTH'
\echo '=================================================='

\echo '--- Check A.1: Database Name, Server Version, and Database Size ---'
SELECT current_database() AS database_name,
       version() AS server_version,
       pg_size_pretty(pg_database_size(current_database())) AS database_size;

\echo '--- Check A.2: Total Public Tables ---'
SELECT count(*) AS public_tables
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE';

\echo '--- Check A.3: Total Public Sequences ---'
SELECT count(*) AS public_sequences
FROM information_schema.sequences
WHERE sequence_schema = 'public';

\echo '--- Check A.4: Current Database Sessions by State ---'
SELECT state, count(*) AS sessions
FROM pg_stat_activity
WHERE datname = current_database()
GROUP BY state;

\echo '--- Check A.5: Basic Table Statistics ---'
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

-- -----------------------------------------------------------------------------
-- B. Database Activity and User Roles
-- -----------------------------------------------------------------------------
\echo '=================================================='
\echo 'B. DATABASE ACTIVITY AND USER ROLES'
\echo '=================================================='

\echo '--- Check B.1: Database Roles and Privileges ---'
SELECT rolname,
       rolcanlogin,
       rolsuper,
       rolcreatedb,
       rolcreaterole
FROM pg_roles
ORDER BY rolname;

\echo '--- Check B.2: Current Active Sessions and Connection Details ---'
SELECT pid,
       usename,
       application_name,
       client_addr,
       state,
       backend_start,
       left(query, 60) AS query
FROM pg_stat_activity
WHERE datname = current_database();

-- -----------------------------------------------------------------------------
-- C. Database Logs
-- -----------------------------------------------------------------------------
\echo '=================================================='
\echo 'C. DATABASE LOGS'
\echo '=================================================='

\echo '--- Check C.1: Logging Configuration Settings ---'
SELECT current_setting('log_destination') AS log_destination,
       current_setting('logging_collector') AS logging_collector,
       current_setting('log_directory') AS log_directory,
       current_setting('log_filename') AS log_filename;

-- -----------------------------------------------------------------------------
-- D. Database Maintenance
-- -----------------------------------------------------------------------------
\echo '=================================================='
\echo 'D. DATABASE MAINTENANCE'
\echo '=================================================='

\echo '--- Check D.1: Execute Safe Maintenance Operation (ANALYZE) on menu_item ---'
ANALYZE public.menu_item;

\echo '--- Check D.2: Verify Table Statistics After ANALYZE ---'
SELECT relname AS table_name,
       n_live_tup AS estimated_live_rows,
       n_dead_tup AS estimated_dead_rows,
       last_vacuum,
       last_autovacuum,
       last_analyze,
       last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
  AND relname = 'menu_item';

-- -----------------------------------------------------------------------------
-- E. Query Execution Plan
-- -----------------------------------------------------------------------------
\echo '=================================================='
\echo 'E. QUERY EXECUTION PLAN'
\echo '=================================================='

\echo '--- Check E.1: Query Execution Plan (EXPLAIN ANALYZE, BUFFERS) ---'
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM public.menu_item
LIMIT 10;
