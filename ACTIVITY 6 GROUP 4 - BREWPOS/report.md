\# BrewPOS - Activity 6: Database Backup and Recovery Report



\## 1. Project Information



\- \*\*Project:\*\* BrewPOS

\- \*\*Database:\*\* `grp\_brewposdb`

\- \*\*Database owner:\*\* `postgres`

\- \*\*PostgreSQL version used:\*\* 14.24

\- \*\*Activity:\*\* Database Backup, Restore, and Recovery

\- \*\*Date performed:\*\* November 6, 2026



\## 2. Objective



The activity aimed to create and verify a PostgreSQL database backup, restore it into a separate test database, validate database objects and application permissions, and perform a controlled recovery simulation.



The original database and backup archive were preserved throughout the tests.



\## 3. Database Structure



| Database Object | Verified Count |

|---|---:|

| Tables | 5 |

| Sequences | 4 |

| Primary keys | 5 |

| Foreign keys | 4 |

| Unique constraints | 2 |

| Check constraints | 5 |

| Indexes | 9 |



The five tables are:



\- `staff`

\- `menu\_category`

\- `menu\_item`

\- `order\_ticket`

\- `order\_line\_item`



\## 4. Backup Creation



A PostgreSQL custom-format archive was created using `pg\_dump`.



\*\*Command:\*\*



```powershell

pg\_dump -U postgres -d grp\_brewposdb -F c -f "C:\\DB\_Backups\\BrewPOS\\grp\_brewposdb\_2026-11-06.dump"

```



\*\*Backup details:\*\*



\- Filename: `grp\_brewposdb\_2026-11-06.dump`

\- Format: Custom (`-Fc`)

\- Location: `C:\\DB\_Backups\\BrewPOS`

\- File size: 16,643 bytes

\- SHA-256: `1588AC4F1E654F9AEA23F0650E27486053B48C676EE77217F47505F97965CB9C`

\- Result: Completed without reported errors.



The archive was inspected using `pg\_restore --list`. Inspection completed successfully and showed 55 TOC entries.



\## 5. Restore Test



A separate empty database named `grp\_brewposdb\_restore\_test` was created.



\*\*Restore command:\*\*



```powershell

pg\_restore -U postgres -d grp\_brewposdb\_restore\_test --no-owner --no-acl "C:\\DB\_Backups\\BrewPOS\\grp\_brewposdb\_2026-11-06.dump"

```



The restore completed without reported errors.



\### 5.1 Data Verification



The original and restored database row counts were checked.



| Table | Original Rows | Restored Rows |

|---|---:|---:|

| staff | 2 | 2 |

| menu\_category | 3 | 3 |

| menu\_item | 11 | 11 |

| order\_ticket | 5 | 5 |

| order\_line\_item | 9 | 9 |



The row counts matched.



\### 5.2 Structure Verification



The restored database contained:



\- 5 tables

\- 4 sequences

\- 5 primary keys

\- 4 foreign keys

\- 2 unique constraints

\- 5 check constraints

\- 9 indexes



The database structure was successfully restored.



\## 6. Access-Control Verification



The BrewPOS application login role is `brewpos\_app`.



The role was verified as a login role without superuser, database creation, or role creation privileges.



The restore used `--no-acl`, so application privileges were explicitly reapplied to the restored database.



\*\*Verified permissions:\*\*



| Table | Allowed Operations |

|---|---|

| staff | SELECT |

| menu\_category | SELECT, INSERT, UPDATE, DELETE |

| menu\_item | SELECT, INSERT, UPDATE, DELETE |

| order\_ticket | SELECT, INSERT |

| order\_line\_item | SELECT, INSERT |



Additional permissions:



\- CONNECT on the restored database

\- USAGE on the public schema

\- No CREATE privilege on the public schema

\- USAGE and SELECT on sequences



\### 6.1 Login and Allowed Operation



The `brewpos\_app` login successfully connected to `grp\_brewposdb\_restore\_test`.



A SELECT COUNT query on `menu\_item` returned 11.



An INSERT test into `menu\_category` succeeded and returned a generated category ID. The transaction was rolled back afterward to keep the test database clean.



\### 6.2 Denied Operations



The application role was tested against operations outside its assigned permissions.



\- UPDATE on `order\_ticket`: denied.

\- DELETE on `order\_ticket`: denied.



Both operations returned permission-denied errors as expected.



The rolled-back test record was also checked and no longer existed.



These results demonstrate that the restored database retained the intended least-privilege application access after privileges were reapplied.



\## 7. Controlled Recovery Simulation



The recovery simulation was performed only on the disposable database `grp\_brewposdb\_restore\_test`.



The original database `grp\_brewposdb` and backup archive were not modified.



\### 7.1 Simulated Data Loss



One test record was identified in `order\_line\_item`:



| Field | Value |

|---|---:|

| order\_id | 1 |

| item\_id | 5 |

| quantity | 2 |

| sold\_price | 90.00 |



The record was deleted from the disposable restore-test database only.



A SELECT query confirmed that the record was missing.



\### 7.2 Recovery Procedure



A new empty database named `grp\_brewposdb\_recovery\_test` was created.



The original backup archive was restored into this fresh database using `pg\_restore` with `--no-owner` and `--no-acl`.



A SELECT query confirmed that the previously deleted record was present again:



| Field | Recovered Value |

|---|---:|

| order\_id | 1 |

| item\_id | 5 |

| quantity | 2 |

| sold\_price | 90.00 |



The recovery database contained 9 rows in `order\_line\_item`.



\### 7.3 Recovery Outcome



The controlled recovery simulation was successful.



The backup restored the deleted test record into a fresh database. The original database and backup file remained unchanged.



\## 8. Recovery Objectives



The following objectives are proposed for a production backup policy:



\- \*\*RPO:\*\* 24 hours, assuming a successful daily backup.

\- \*\*RTO:\*\* 2 hours for this small database, including restoration and verification.



These are planning targets and were not established as measured service guarantees during this exercise.



\## 9. Limitations and Recommendations



1\. The local PostgreSQL version used for this activity was 14.24, while the BrewPOS project documentation targets PostgreSQL 18.6 and states support for PostgreSQL 16 or later. Compatibility should be retested using the documented supported version.

2\. Only one local backup archive was created during this exercise. A second protected or off-site copy is recommended.

3\. Daily backup scheduling and retention are proposed but are not automated.

4\. PostgreSQL roles and memberships are cluster-level objects. They must be backed up or recreated separately when recovering to a different PostgreSQL cluster.

5\. The restore used `--no-owner` and `--no-acl`. Required application permissions were reapplied and tested manually.

6\. Periodic restore testing is recommended to ensure that backup archives remain usable.



\## 10. Conclusion



The BrewPOS database backup, archive inspection, separate-database restore, data verification, and controlled recovery simulation were completed successfully.



All five tables and their expected row counts were verified after restoration. Application login, permitted operations, and denied operations were also tested.



The deleted test record was recovered successfully from the backup into a fresh recovery database. The original database and backup archive were preserved.



\## 11. Evidence



Screenshots and supporting files should be stored alongside this report in the Activity 6 project folder.



Recommended evidence:



\- Backup archive file information

\- SHA-256 checksum output

\- `pg\_restore` archive listing

\- Restore database table and row-count verification

\- Constraint and index verification

\- Application-role login and permission verification

\- Allowed INSERT test and rollback

\- Denied UPDATE and DELETE tests

\- Simulated deletion from the disposable restore-test database

\- Successful recovery of the deleted record

\- Final recovered order-line count



\## 12. AI Usage Declaration



AI assistance was used to help organize the backup and recovery plan, explain PostgreSQL commands, troubleshoot errors, and prepare technical documentation.



All database commands were executed and their results were checked by the student. The report was reviewed and finalized by the student to ensure that it accurately reflects the work performed.

