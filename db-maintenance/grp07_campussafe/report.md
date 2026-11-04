# Activity 5: Database Monitoring and Maintenance Report

## Group Information

- Evaluating Group: Group 2
- Evaluated Project: Group 7 – CampusSafe
- Database Name: `grp07_campussafedb`
- PostgreSQL Version: 14.24

## 1. Introduction

This activity focuses on monitoring and maintaining the PostgreSQL database of Group 7's CampusSafe system. The inspection covered database health, user activity, PostgreSQL logs, table and index conditions, and query performance.

## 2. Database Health and Activity

The database was accessible during inspection.

- Database size: 9,491 kB
- Total public tables: 9
- Connected backend sessions: 1 during inspection
- No long-running query was identified in the inspected activity snapshot.

The six Activity 4 roles and accounts were present. The three login accounts were assigned to their corresponding group roles.

## 3. PostgreSQL Log Review

The inspected logs contained the following events:

- Permission-denied events during database access-control tests.
- Failed authentication attempts involving CampusSafe accounts and a nonexistent role named `hp`.
- A statistics-file permission warning.
- Client connection interruptions.
- SQL syntax and table-column errors.
- PostgreSQL startup and shutdown events.

The permission-denied events are consistent with access restrictions being tested. Other events require review, although their exact causes were not established by the logs alone.

## 4. Database Maintenance Inspection

The nine public tables, their sizes, existing indexes, estimated live rows, and estimated dead rows were inspected.

Most tables had zero estimated dead rows. The `report_status_history` table had two estimated dead rows.

All nine public tables were owned by `postgres`. The Activity 4 login accounts were not established as table owners.

**Maintenance limitation:** VACUUM and ANALYZE were not executed because an authorized maintenance account or approval to perform these operations had not been established. The inspection results and this limitation were documented rather than bypassing the existing permissions.

## 5. Query Performance Analysis

The selected query retrieves submitted hazard reports and sorts them by submission date, newest first.

PostgreSQL used the existing `idx_report_status` index, followed by a Bitmap Heap Scan and Sort operation.

EXPLAIN ANALYZE results:

- Estimated rows: 2
- Actual rows: 2
- Planning time: 0.380 ms
- Execution time: 1.005 ms

The estimated and actual row counts matched. The query performed efficiently with the current small dataset. No additional index was recommended at this time.

## 6. Recommendations

1. Review unsuccessful authentication attempts and verify the intended database connection settings.
2. Check the PostgreSQL statistics-directory permissions.
3. Continue monitoring unexpected client disconnections.
4. Verify SQL statements against the actual database table structures.
5. Use an authorized maintenance account for future VACUUM and ANALYZE operations.
6. Monitor query performance as the number of hazard reports increases.

## 7. Conclusion

The Group 7 CampusSafe database was operational during the inspection. Its tables and indexes were present, and the selected application query performed efficiently.

The log review identified several events that should be monitored. Maintenance commands were not executed because the required authorization had not been established. Overall, the inspection provided a record of the database's observed condition and recommendations for future maintenance.

## 8. Evidence

Screenshots and supporting files are organized in the following folders:

- `evidence/health/`
- `evidence/activity/`
- `evidence/logs/`
- `evidence/maintenance/`
- `evidence/query-performance/`

Supporting documentation:

- `health-inspection.md`
- `log-review.md`
- `query-analysis.md`
- `maintenance.sql`