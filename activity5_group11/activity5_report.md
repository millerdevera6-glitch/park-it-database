# Activity 5 — Database Maintenance and Monitoring Report

**Run date:** 2026-11-06

**Environment:** PostgreSQL 18.6 on x86_64-windows (msvc-19.44.35228, 64-bit), Target Database: `boardtrack_db` (Host: localhost:5432)

**Scope:** Database inspection and limited maintenance of the group's existing project database (BoardTrack — Boarding House & Rental Management System). Results describe the inspected environment and must not be presented as production workload measurements.

### Results

| Check | Result |
|---|---|
| Health | **PARTIAL** — PostgreSQL 18.6 server confirmed active and responsive on port 5432; current connected instance database size is 8,014 kB with 1 active session. The project configuration specifies target database `boardtrack_db` with 7 relational base tables (`property`, `room`, `tenant`, `lease`, `payment`, `utility_bill`, `app_user`), 1 tracking table (`schema_migrations`), and 1 view (`v_lease_summary`), but direct connection to `boardtrack_db` failed with confirmed server error `FATAL: database "boardtrack_db" does not exist`. |
| Activity and roles | **PARTIAL** — Active server session inspection returned 1 active superuser session (`postgres` via `::1`). Cluster roles inspection confirmed administrative superuser privileges (`postgres`: `rolsuper=t`, `rolcreatedb=t`, `rolcreaterole=t`) and 16 built-in PostgreSQL system roles. Custom project roles defined in `docs/user-roles.md` (`boardtrack_owner`, `boardtrack_admin_grp`, `app_runtime_grp`, `app_readonly_grp`, `boardtrack_app`) have not yet been provisioned on the live cluster. |
| Logs | **PASS** — Logging configuration verified through system catalog settings: `log_destination = 'stderr'`, `logging_collector = 'on'`, `log_directory = 'log'`, and `log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'`. Active log file `postgresql-2026-11-06_140117.log` verified via `pg_current_logfile()` and `current_logfiles` on disk; inspected log records captured server checkpoints, connection attempts, the missing database error (`FATAL: database "boardtrack_db" does not exist`), and relation errors. |
| Maintenance | **FAIL** — Attempted safe maintenance operation `ANALYZE public.property;` on the project's representative primary table. Execution was confirmed against the live PostgreSQL 18 server and returned `ERROR: relation "public.property" does not exist` because project schema migrations have not been applied to the live instance. Per activity restrictions, no migrations or schema modifications were performed. |
| Query plan | **FAIL** — Formulated representative read-only query `EXPLAIN (ANALYZE, BUFFERS) SELECT property_id, property_name, address FROM public.property LIMIT 10;`. Execution on the live PostgreSQL 18 instance returned `ERROR: relation "public.property" does not exist at character 76`; query planner metrics and buffer execution timings could not be produced due to the absent table relation. |

### Limitations

1. **Unprovisioned Target Database and Project Roles:** The repository configuration files (`.env.example`, `README.md`, `docs/database.md`, `docs/user-roles.md`) configure target database `boardtrack_db` and roles `boardtrack_owner`, `boardtrack_admin_grp`, `app_runtime_grp`, `app_readonly_grp`, and `boardtrack_app`. On the active local PostgreSQL 18 cluster, `boardtrack_db` does not exist (`FATAL: database "boardtrack_db" does not exist`), and project-specific custom roles have not been created.
2. **Strict Non-Destructive Adherence:** In strict compliance with Activity 5 restrictions (Rules 2, 5, and 6), no new database was created, no migrations were run, and no schema or data modifications were made to bypass this state.
3. **Execution Plan and Maintenance Constraints:** Maintenance (`ANALYZE`) and execution plan (`EXPLAIN ANALYZE`) queries were executed against the live database server and produced confirmed catalog relation errors rather than execution metrics.
4. **Non-Production Workload:** The inspected environment is a local developer installation and does not reflect production concurrent traffic, transaction volumes, query workloads, or log retention policies.

### Evidence Files

- `activity5_evidence/activity5_checks.sql` — Exact SQL queries executed across the five checklist categories with documentation comments.
- `activity5_evidence/query_results.txt` — Verbatim command outputs, server diagnostic logs, catalog query results, and connection attempt records.
- `activity5_evidence/activity5_report.md` — The finalized Activity 5 Database Maintenance and Monitoring Report.

