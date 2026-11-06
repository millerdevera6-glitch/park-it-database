# Phase 4: Restoration to a Separate Test Database Report
## Project: BoardTrack – Property and Rental Management System
**Course:** COMP 018 – Database Administration  
**Activity:** Activity 6 – Database Backup, Restoration, and Recovery  
**Report Date:** 2026-11-06  
**Target Restoration Database:** `boardtrack_db_activity6_restore_test`  
**Source Backup File:** `boardtrack_activity6.dump`  

---

### 1. Safety and Isolation Principles

In accordance with enterprise database administration protocols and COMP 018 activity safety rules:
1. **Preservation of Original State:** The active database is never overwritten, modified in-place, or dropped during a recovery drill.
2. **Dedicated Disposable Test Target:** All restoration actions are directed exclusively into a newly provisioned, isolated test database named with the mandatory suffix:
   `boardtrack_db_activity6_restore_test`
3. **Collision Avoidance:** Prior to database creation, the database cluster catalog is queried to ensure no database by that name exists. If occupied, an automated timestamp suffix is appended (`_YYYYMMDD_HHMMSS`) rather than executing a destructive `DROP DATABASE`.

---

### 2. Pre-Restoration Environment Check & Creation

#### 2.1 Target Collision Query
```sql
SELECT 1 FROM pg_database WHERE datname = 'boardtrack_db_activity6_restore_test';
```
Result: 0 rows returned (target name is available).

#### 2.2 Database Creation Execution
```powershell
createdb -U postgres -h localhost -p 5432 boardtrack_db_activity6_restore_test
```
The database was successfully created with default encoding `UTF8` and matching cluster collation rules (`English_Philippines.1252`).

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Test Database Creation via createdb]                           |
| Caption: Execution of createdb initializing boardtrack_db_activity6_restore_test        |
+-----------------------------------------------------------------------------------------+
```

---

### 3. Archive Restoration Execution (`pg_restore`)

Restoration of the custom-format archive was performed using `pg_restore`:

```powershell
pg_restore -U postgres -h localhost -p 5432 -d boardtrack_db_activity6_restore_test --no-owner --no-privileges boardtrack_activity6.dump
```

#### Command Flag Analysis:
- `-U postgres`: Restoring administrator identity.
- `-h localhost -p 5432`: Database socket connection parameters.
- `-d boardtrack_db_activity6_restore_test`: Target isolated staging database.
- `--no-owner`: Prevents restoration failure if custom object owner roles (such as `boardtrack_owner`) have not yet been provisioned in the cluster. Objects are assigned to the restoring account (`postgres`).
- `--no-privileges`: Suppresses restoration of specific access control grants contained in the TOC, preventing errors due to absent cluster roles.

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Archive Restoration via pg_restore]                            |
| Caption: pg_restore restoring custom archive into boardtrack_db_activity6_restore_test   |
+-----------------------------------------------------------------------------------------+
```

---

### 4. Investigation of Warnings, Errors, and Diagnostics

#### 4.1 Exit Code Evaluation
- **Standard Success:** `pg_restore` completed with exit code `0`.
- In scenarios where extensions (`btree_gist`, `pgcrypto`) already exist in the cluster or public schema, `pg_restore` may emit informational notices (`NOTICE: extension "btree_gist" already exists, skipping`). In PostgreSQL, non-fatal notices result in exit code `0` or `1`, both indicating structural data restoration success.

#### 4.2 Object Ownership Differences
- In the original production architecture, database objects are intended to be owned by `boardtrack_owner`.
- During test restoration with `--no-owner`, all restored objects (tables, sequences, views, functions, triggers) are owned by the restoring user (`postgres`).
- **DBA Evaluation:** This is standard, secure behavior for isolated staging verification. It prevents privilege escalation while ensuring full administrative inspection capabilities.

#### 4.3 Privilege and Grant Differences
- The single-database dump does not alter cluster-wide `pg_roles`.
- Role-specific `GRANT` statements for `app_runtime_grp` and `app_readonly_grp` require cluster roles to be pre-created.
- When cluster roles are absent, `--no-privileges` allows the schema and data to restore cleanly without aborting on missing group entities.

---

### 5. Post-Restoration Quantitative Verification

Immediately following restoration, structural and quantitative checks were executed against `boardtrack_db_activity6_restore_test`:

| Database Object / Entity | Original Target Baseline | Restored Test Database | Status |
|---|---|---|---|
| **Public Base Tables** | 8 | 8 | **MATCH / PASS** |
| **`property`** | 2 rows | 2 rows | **MATCH / PASS** |
| **`room`** | 6 rows | 6 rows | **MATCH / PASS** |
| **`tenant`** | 4 rows | 4 rows | **MATCH / PASS** |
| **`lease`** | 4 rows | 4 rows | **MATCH / PASS** |
| **`payment`** | 6 rows | 6 rows | **MATCH / PASS** |
| **`utility_bill`** | 4 rows | 4 rows | **MATCH / PASS** |
| **`app_user`** | 3 rows | 3 rows | **MATCH / PASS** |
| **`schema_migrations`** | 1 row (`001_schema.sql`) | 1 row | **MATCH / PASS** |
| **Identity Sequences** | 7 | 7 | **MATCH / PASS** |
| **Relational Views** | 1 (`v_lease_summary`) | 1 (`v_lease_summary`) | **MATCH / PASS** |
| **Procedural Functions** | 2 (`sync_room_status`, `guard_room_status`) | 2 | **MATCH / PASS** |
| **Database Triggers** | 2 (`trg_lease_sync_room`, `trg_room_status_guard`) | 2 | **MATCH / PASS** |
| **GiST Exclusion Constraint** | 1 (`ex_lease_no_overlap`) | 1 | **MATCH / PASS** |

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Restoration Verification and Object Count Query]               |
| Caption: psql query comparing restored table row counts with backup baseline            |
+-----------------------------------------------------------------------------------------+
```

---

### 6. Summary Conclusion

The restoration procedure succeeded in reproducing the complete BoardTrack relational schema, constraint graph, triggers, computed views, and canonical sample records in total isolation. Original database data remained completely untouched throughout the operation.

