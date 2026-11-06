# Activity 5 — Database Maintenance and Monitoring Report

**Run date:** 2026-11-06

**Environment:** PostgreSQL 18.6 on x86_64-windows (msvc-19.44.35228, 64-bit), Target Database: `canteen_db` (Host: localhost:5432)

**Scope:** Database inspection and limited maintenance of the group's existing project database (Campus Canteen Pre-Order and Queue Management System by bwisIT Solutions). Results describe the inspected environment and must not be presented as production workload measurements.

### Results

| Check | Result |
|---|---|
| Health | PARTIAL — PostgreSQL 18.6 server confirmed active and responsive on port 5432; current connected instance database size is 8,014 kB with 1 active session. The project configuration specifies target database `canteen_db` with 7 planned relational tables (`student`, `vendor`, `menu_item`, `customer_order`, `order_item`, `queue_entry`, `notification`), but direct connection to `canteen_db` failed with confirmed server error `FATAL: database "canteen_db" does not exist`. |
| Activity and roles | PARTIAL — Active server session inspection returned 1 active superuser session (`postgres` via `::1`). Cluster roles inspection confirmed administrative superuser privileges (`postgres`: `rolsuper=t`, `rolcreatedb=t`, `rolcreaterole=t`) and 16 built-in PostgreSQL system roles. Custom project roles defined in `db-access-control/01-create-roles.sql` (`canteen_admin`, `canteen_app`, `canteen_readonly`, `canteen_app_grp`, `canteen_readonly_grp`) have not yet been provisioned on the live cluster. |
| Logs | PASS — Logging configuration verified through system catalog settings: `log_destination = 'stderr'`, `logging_collector = 'on'`, `log_directory = 'log'`, and `log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'`. Active log file `postgresql-2026-11-06_140117.log` verified via `current_logfiles` on disk; inspected log records captured server checkpoints, connection attempts, the missing database error (`FATAL: database "canteen_db" does not exist`), and unmigrated table queries (`ERROR: relation "public.student" does not exist`). |
| Maintenance | FAIL — Attempted safe maintenance operation `ANALYZE public.student;` on the project's representative primary table. Execution was confirmed against the live PostgreSQL 18 server and returned `ERROR: relation "public.student" does not exist` because project schema migrations have not been applied to the live instance. Per activity restrictions, no migrations or schema modifications were performed. |
| Query plan | FAIL — Formulated representative read-only query `EXPLAIN (ANALYZE, BUFFERS) SELECT student_id, full_name, email, role, created_at FROM public.student LIMIT 10;`. Execution on the live PostgreSQL 18 instance returned `ERROR: relation "public.student" does not exist at character 87`; query planner metrics and buffer execution timings could not be produced due to the absent table relation. |

### Limitations

1. **Unprovisioned Target Database and Project Roles:** The repository configuration files (`application.properties`, `.env.example`, `database/setup.ps1`) configure target database `canteen_db` and roles `canteen_admin`/`canteen_app`. On the active local PostgreSQL 18 cluster, `canteen_db` does not exist (`FATAL: database "canteen_db" does not exist`), and project-specific custom roles have not been created.
2. **Strict Non-Destructive Adherence:** In strict compliance with Activity 5 restrictions (Rules 2, 5, and 6), no new database was created, no migrations were run, and no schema or data modifications were made to bypass this state.
3. **Execution Plan and Maintenance Constraints:** Maintenance (`ANALYZE`) and execution plan (`EXPLAIN ANALYZE`) queries were executed against the live database server and produced confirmed catalog relation errors rather than execution metrics.
4. **Non-Production Workload:** The inspected environment is a local developer installation and does not reflect production concurrent traffic, transaction volumes, query workloads, or log retention policies.

### Evidence Files

- `activity5_evidence/activity5_checks.sql` — Exact SQL queries executed for the five checklist categories with documentation comments.
- `activity5_evidence/query_results.txt` — Verbatim command outputs, server diagnostic logs, catalog query results, and connection attempt records.
- `activity5_evidence/activity5_report.md` — The finalized Activity 5 Database Maintenance and Monitoring Report.

