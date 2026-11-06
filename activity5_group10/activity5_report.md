# Activity 5 — Database Maintenance and Monitoring Report

**Run date:** 2026-11-06

**Environment:** PostgreSQL 18.6 on x86_64-windows (msvc-19.44.35228, 64-bit), Database: `grp_binarysisters_projectdb`

**Scope:** Database inspection and limited maintenance of the group's existing project database. Results describe the inspected environment and must not be presented as production workload measurements.

### Results

| Check | Result |
|---|---|
| Health | **PASS** — Database `grp_binarysisters_projectdb` is accessible with an on-disk size of 8,902 kB. Identified 8 public base tables (`customer`, `menu_item`, `order_item`, `orders`, `payment`, `reservation`, `restaurant_table`, `staff`), 7 sequences, and 4 views. Currently 1 active session connected; all tables show 0 estimated live and dead rows. |
| Activity and roles | **PASS** — Inspected 17 cluster roles in `pg_roles` and active sessions in `pg_stat_activity`. Only `postgres` possesses login (`rolcanlogin = t`) and administrative superuser privileges (`rolsuper = t`, `rolcreatedb = t`, `rolcreaterole = t`). The project-specified application roles (`rors_app`, `rors_report`, `rors_maint`, `rors_backup`, `rors_dba`) from `access_control_plan.md` have not yet been instantiated in this cluster. One active session was observed executing the inspection queries. |
| Logs | **PASS** — Logging collector is enabled (`logging_collector = on`) directing stderr output to `log/postgresql-%Y-%m-%d_%H%M%S.log`. Directly inspected active log file `log/postgresql-2026-11-06_140117.log`, verifying normal checkpoint events, database startup, client disconnections, and authentication logs without critical server failures. |
| Maintenance | **PASS** — Executed safe maintenance operation `ANALYZE public.menu_item;` on the representative menu item table. Verified via `pg_stat_user_tables` that `last_analyze` was updated to `2026-11-06 16:14:19.607392+08` with 0 dead tuples. |
| Query plan | **PASS** — Ran `EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM public.menu_item LIMIT 10;`. The planner selected a Sequential Scan (`Seq Scan on menu_item`). Query completed with a Planning Time of 0.161 ms, an Execution Time of 0.018 ms, and 16 shared hit buffers. |

### Limitations

1. **Small Dataset & Lack of Production Workload:** The local database contains schema structures without populated transactional rows (0 rows across tables). The sequential scan selection and sub-millisecond query timings reflect empty local tables and cannot represent production workload performance or index efficiency.
2. **Cluster Roles Incomplete:** The custom least-privilege roles specified in the project documentation (`rors_app`, `rors_maint`, `rors_report`, etc.) were not present in the PostgreSQL cluster instance, so inspection was performed under the available `postgres` role.
3. **Local Inspection Environment:** All observations derive from a local standalone database instance without network latency, continuous background transactions, connection poolers, or concurrent locking contention.

### Evidence Files

- `activity5_checks.sql` — Exact SQL script executed across all five checklist categories with annotated comments.
- `query_results.txt` — Verbatim query output and log file excerpts captured directly from the database engine.
- `activity5_report.md` — Final summary report document.

