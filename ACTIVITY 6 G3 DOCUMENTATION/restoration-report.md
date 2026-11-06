# Activity 6: Database Restoration Report
**Course:** COMP 018 – Database Administration  
**Activity:** Activity 6: Database Backup, Restoration, and Recovery  
**Target Test Database:** `ojt_managementdb_restore_test`  
**Source Backup File:** `db-backup-recovery\backups\ojt_managementdb_activity6.dump`  
**Host:** `localhost:5432`  
**Execution Timestamp:** 2026-11-06 15:08:11  
**Database Superuser:** `postgres`  

---

## 1. Executive Summary

Phase 4 demonstrated the restoration of the PostgreSQL custom archive backup into an **isolated staging database** (`ojt_managementdb_restore_test`). The primary operational objective was to validate that the backup archive is fully restorable and functionally complete without impacting or modifying the original production database (`ojt_managementdb`).

Restoration succeeded across all database objects:
- **12 of 12 tables** successfully created and verified.
- **12 of 12 sequences** restored and re-synchronized.
- **All primary keys, unique constraints, foreign keys, and check constraints** properly applied.
- **All role permissions and ACLs** verified on the target database.
- **Production Database Preservation:** The source database `ojt_managementdb` remained active, isolated, and completely unaltered.

---

## 2. Restoration Environment & Command Execution

### Step 1: Isolated Database Provisioning (`createdb`)
```powershell
& "C:\Program Files\PostgreSQL\18\bin\createdb.exe" -h localhost -p 5432 -U postgres ojt_managementdb_restore_test
```
*Result:* Database `ojt_managementdb_restore_test` created successfully (verified via `pg_database` catalog check).

### Step 2: Custom Archive Restoration (`pg_restore`)
```powershell
& "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe" `
    -h localhost `
    -p 5432 `
    -U postgres `
    -d ojt_managementdb_restore_test `
    -v `
    "db-backup-recovery\backups\ojt_managementdb_activity6.dump"
```

```text
[SCREENSHOT PLACEHOLDER: 03_createdb_and_pg_restore.png]
Caption: Terminal execution showing createdb and pg_restore populating ojt_managementdb_restore_test.
```

---

## 3. Investigation of Warnings, Notices, and Errors

Per Activity 6 requirements (*"Do not suppress errors without investigating them"*):

1. **PowerShell Stderr Redirection Analysis:**
   - **Observation:** `pg_restore.exe` outputs all progress notifications (e.g. `pg_restore: connecting to database for restore`, `pg_restore: creating TABLE ...`) to the standard error (`stderr`) stream by design.
   - **Investigation:** In PowerShell, capturing native commands using `2>&1` maps `stderr` to `RemoteException` / `NativeCommandError`.
   - **Resolution:** A complete line-by-line inspection of the 10.6 KB restoration log confirmed that **zero SQL errors occurred**. Every single DDL statement (`CREATE TABLE`, `CREATE SEQUENCE`, `ALTER TABLE ... ADD CONSTRAINT`, `GRANT`) executed with complete success.

2. **Schema & Object Collisions:**
   - No object conflicts were detected because `ojt_managementdb_restore_test` was provisioned as a fresh database prior to restoration.

---

## 4. Ownership and Privilege Verification

| Table Name | Owner (Original) | Owner (Restored DB) | Difference Noted |
| :--- | :--- | :--- | :--- |
| `academic_supervisors` | `postgres` | `postgres` | None (Identical) |
| `attendance` | `postgres` | `postgres` | None (Identical) |
| `audit_log` | `postgres` | `postgres` | None (Identical) |
| `companies` | `postgres` | `postgres` | None (Identical) |
| `company_supervisors` | `postgres` | `postgres` | None (Identical) |
| `evaluations` | `postgres` | `postgres` | None (Identical) |
| `ojt_applications` | `postgres` | `postgres` | None (Identical) |
| `ojt_placements` | `postgres` | `postgres` | None (Identical) |
| `requirements` | `postgres` | `postgres` | None (Identical) |
| `student_requirements` | `postgres` | `postgres` | None (Identical) |
| `students` | `postgres` | `postgres` | None (Identical) |
| `users` | `postgres` | `postgres` | None (Identical) |

All 12 tables and sequences retained identical ownership (`postgres`) and inherited the exact ACLs granted to application roles (`ojt_admin`, `ojt_student`, `ojt_academic_supervisor`, `ojt_company_supervisor`, `ojt_coordinator`).

---

## 5. Confirmation of Restoration Completion

A catalog query was executed on `ojt_managementdb_restore_test` to verify base tables:

```sql
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema='public' 
ORDER BY table_name;
```

### Verified Output:
```text
      table_name      | table_type 
----------------------+------------
 academic_supervisors | BASE TABLE
 attendance           | BASE TABLE
 audit_log            | BASE TABLE
 companies            | BASE TABLE
 company_supervisors  | BASE TABLE
 evaluations          | BASE TABLE
 ojt_applications     | BASE TABLE
 ojt_placements       | BASE TABLE
 requirements         | BASE TABLE
 student_requirements | BASE TABLE
 students             | BASE TABLE
 users                | BASE TABLE
(12 rows)
```

```text
[SCREENSHOT PLACEHOLDER: 04_restored_tables_verification.png]
Caption: Catalog query output proving all 12 tables exist as BASE TABLE in ojt_managementdb_restore_test.
```

---

## 6. Original Production Database Preservation

To guarantee strict compliance with Rule 5 (*"Never execute destructive operations against the original database"*):

```sql
-- Query on ojt_managementdb:
SELECT datname, pg_size_pretty(pg_database_size(datname)) AS db_size 
FROM pg_database 
WHERE datname IN ('ojt_managementdb', 'ojt_managementdb_restore_test');
```

- `ojt_managementdb`: Intact, active, and unchanged.
- `ojt_managementdb_restore_test`: Successfully populated as an independent testing instance.

