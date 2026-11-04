# PostgreSQL Log Review – Group 7 CampusSafe

## 1. Log Configuration

The PostgreSQL logging configuration was inspected.

- Log destination: stderr
- Logging collector: enabled
- Log directory: log
- Log filename pattern: postgresql-%Y-%m-%d_%H%M%S.log

## 2. Findings

### Permission Denied Errors

The logs recorded permission-denied errors involving tables such as hazard_report, app_user, and report_status_history.

These indicate that the tested database accounts could not perform certain operations.

Impact: These restrictions may prevent users from performing unauthorized database actions.

Recommendation: Review the assigned roles and privileges to ensure they match the application's requirements.

### Authentication Failures

The logs recorded failed authentication attempts for campussafe_app, campussafe_report, campussafe_backup, and an unrecognized role named hp.

Impact: Failed authentication prevents the affected accounts from connecting.

Recommendation: Verify account credentials and investigate the unrecognized role entry with the database administrator.

### Statistics Warning

A permission-related warning occurred while PostgreSQL attempted to update temporary statistics files.

Impact: Database statistics may not have been updated correctly at that time.

Recommendation: Monitor PostgreSQL logs and check the server's file permissions if the warning continues.

### Server Shutdown and Client Disconnections

The logs recorded server shutdown events and client connections being closed.

Impact: These events may interrupt database activity.

Recommendation: Check whether shutdowns were planned and monitor for unexpected disconnections.

### SQL Errors

The logs also recorded SQL syntax errors and a reference to a missing changed_by column in report_status_history.

Impact: Incorrect SQL statements or mismatched column names can cause application operations to fail.

Recommendation: Review the affected SQL statements and compare them with the actual database table structure.

## 3. Limitations

The inspected logs contain events from the PostgreSQL server and may include activity from databases other than CampusSafe. The exact cause of some authentication failures and client disconnections could not be established from the available log entries.

## 4. Conclusion

The log review identified permission-denied events, authentication failures, a statistics warning, shutdown and disconnection events, and SQL errors. These findings provide areas for further database administration and monitoring.