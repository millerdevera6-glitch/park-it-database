# Activity 5 — Database Maintenance and Monitoring Report

**Run date:** 2026-11-06

**Environment:** PostgreSQL 18.x on Windows (x86_64), Database: `grp05_lostandfounddb` (Host: localhost:5432)

**Scope:** Database inspection and limited maintenance of the group's existing project database. Results describe the inspected environment and must not be presented as production workload measurements.

### Results

| Check | Result |
|---|---|
| Health | PARTIAL — PostgreSQL 18 service confirmed running and accepting connections on port 5432 (`pg_isready` exit code 0). Project schema defines 8 application base tables and 8 serial sequences. In-engine catalog queries could not be executed due to unconfigured local connection credentials (`fe_sendauth: no password supplied`). |
| Activity and roles | PARTIAL — Custom project roles (`lostandfound_app`, `lostandfound_public`) and superuser (`postgres`) were inspected from project SQL scripts. `lostandfound_app` adheres to least privilege; `lostandfound_public` holds potentially excessive direct table write privileges. Active session and system catalog queries could not be executed on the live cluster. |
| Logs | PASS — Logging configuration directly verified from `postgresql.conf` (`log_destination = 'stderr'`, `logging_collector = on`, `log_directory = 'log'`). Active log file `postgresql-2026-11-06_140117.log` verified via `current_logfiles` on disk (clean startup, no logged errors). |
| Maintenance | PARTIAL — Safe `ANALYZE public.items;` operation was formulated for the primary representative table. Live execution was prevented due to password authentication restrictions on the local instance. |
| Query plan | PARTIAL — Representative read-only query and execution plan (`EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM public.items LIMIT 10;`) formulated and evaluated. Live planner output could not be obtained due to authentication restrictions. |

### Limitations

1. **Authentication Restrictions and Environment Setup:** The project repository contains `.env.example` but no active `.env` file with configured database credentials. The local PostgreSQL 18 installation enforces SCRAM-SHA-256 authentication (`fe_sendauth: no password supplied`), preventing unauthenticated interactive query execution.
2. **Configuration Inspection vs. In-Engine Execution:** Server configuration and log files were verified directly through file system and service health utilities, but database-internal catalog queries (`pg_stat_activity`, `pg_roles`, `pg_stat_user_tables`) could not be run without valid credentials.
3. **Absence of Production Workload:** The database environment is local/development, containing minimal data. Query execution plans in small development setups naturally favor sequential scans over index scans due to table size, which does not represent production workload performance.

### Evidence Files

- `activity5_evidence/activity5_checks.sql` — Exact SQL queries prepared for the 5-point inspection, maintenance, and query planning checks.
- `activity5_evidence/query_results.txt` — Diagnostic outputs, service status verification, configuration evidence, and connection test transcripts.
- `activity5_evidence/activity5_report.md` — The finalized Activity 5 Database Maintenance and Monitoring Report.

