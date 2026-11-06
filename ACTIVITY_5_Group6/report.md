# Activity 5 — HabalGo Database Maintenance and Monitoring Report

**Run date:** 2026-11-06  
**Environment:** PostgreSQL 18.6 on Windows; `grp00_habalgodb` database; `habalgo` schema. Results are from the local HabalGo test database.

## Results

| **Check** | **Result** |
|---|---|
| Health | PASS — PostgreSQL 18.6; 8 tables and 7 sequences in the `habalgo` schema. Database size and session count were not included in the captured results. |
| Activity and roles | PASS — Four HabalGo roles were returned. Both group roles were non-login roles, while both application accounts had login access. All four roles remained non-superuser and without `CREATEDB`/`CREATEROLE`. Permission checks confirmed that the application account could INSERT and UPDATE, while the read-only account could SELECT but could not INSERT. |
| Logs | PARTIAL — `log_destination=stderr`, `logging_collector=on`, `log_directory=log`, and the configured filename pattern was `postgresql-%Y-%m-%d_%H%M%S.log`. Actual log entries and log-retention behavior were not inspected. |
| Maintenance | PASS — `ANALYZE` was recorded for `habalgo.booking`. The table statistics showed an estimated 0 live rows and 0 dead rows. The recorded last vacuum was November 6, 2026, at 00:31:10, and the last analyze was at 02:26:04 (UTC+8). No separate VACUUM operation was performed as part of this check. |
| Query plan | PASS — A read-only `EXPLAIN (ANALYZE, BUFFERS)` query completed on `habalgo.booking`. PostgreSQL used a sequential scan followed by a sort. The query returned 0 rows, with a planning time of 0.171 ms and execution time of 0.030 ms. These timings are not representative production performance results. |

**Limitations:** Testing was limited to the local HabalGo database. The supplied sample data did not include booking records, and the inspected booking table had an estimated 0 live rows. Consequently, the query-plan results reflect an empty or very small table rather than a production workload. Actual server log contents, log-retention behavior, and production maintenance requirements were not assessed.