# Activity 6 – Recovery Simulation

## 1. Recovery Objective
The purpose of this simulation was to verify that the CampusSafe database could be recovered using the previously created logical backup.

## 2. Recovery Procedure
A separate recovery database named `grp07_campussafedb_recovery_test` was created. The original database and the existing restoration test database were left unchanged.

The backup file `grp07_campussafedb_activity6.dump` was restored into the new recovery database using PostgreSQL's `pg_restore` utility.

## 3. Recovery Verification

The recovered database was checked using SQL record-count queries.

| Table | Recovered Records |
|---|---:|
| app_user | 6 |
| hazard_report | 16 |
| report_status_history | 60 |
| role | 5 |

All checked record counts matched the earlier restoration test.

## 4. Result
The recovery test was successful. The backup was restored into a separate recovery database without reported errors, and the expected records were present.

The original CampusSafe database remained unchanged.

## 5. Limitations
This was a controlled recovery test using a fresh database, not an actual production database failure. The exact recovery time was not measured, so the planned RTO of four hours has not yet been independently validated.