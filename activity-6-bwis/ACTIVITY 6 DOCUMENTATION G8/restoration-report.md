# Phase 4: Database Restoration Report

**Project:** BWIS IT Solutions – Campus Canteen Pre-Order & Queue Management System  
**Restoration Source:** `bwis_activity6.dump` (SHA-256: `8C89EE1569E2...`)  
**Target Test Database:** `canteendb_activity6_restore_test`  
**Execution Timestamp:** 2026-11-06 17:47:16 +08:00  
**DBA Lead:** Senior PostgreSQL Database Administrator  

---

## 1. Safety Pre-Check and Target Database Provisioning

To uphold database administration safety guidelines and guarantee that the original production database (`canteendb`) remained 100% isolated and unaltered:

1. **Existence Verification:** Prior to creation, a catalog check was executed against `pg_database`:
   ```sql
   SELECT 1 FROM pg_database WHERE datname = 'canteendb_activity6_restore_test';
   ```
   *Result:* 0 rows returned (target name was unoccupied).
2. **Dedicated Test Database Creation:** A separate test database was created using the PostgreSQL `createdb` utility:
   ```powershell
   createdb -U postgres -h 127.0.0.1 -p 5432 canteendb_activity6_restore_test
   ```
   *Exit Code:* `0` (Success).

---

## 2. Restoration Execution Details

The verified custom archive was restored into `canteendb_activity6_restore_test` using `pg_restore`.

### Command Line Executed
```powershell
pg_restore -U postgres -h 127.0.0.1 -p 5432 -d canteendb_activity6_restore_test --verbose "C:\Users\Matt\.gemini\antigravity\brain\878ad063-ef98-453d-8141-37794cfa9983\scratch\bwis_activity6.dump"
```

### Execution Log & Process Analysis
- **Execution Mode:** Multi-phase verbose restoration (`--verbose`).
- **Processing Phases Completed:**
  1. `pg_restore: connecting to database for restore`
  2. `pg_restore: executing SELECT pg_catalog.set_config('search_path', '', false);`
  3. `pg_restore: creating TABLE` (All 7 tables created)
  4. `pg_restore: creating SEQUENCE` and `SEQUENCE OWNED BY` (All 7 sequences created and linked to primary keys)
  5. `pg_restore: creating DEFAULT` (All auto-increment defaults established)
  6. `pg_restore: processing data for table` (Data streams ingested)
  7. `pg_restore: executing SEQUENCE SET` (Sequence counters synchronized)
  8. `pg_restore: creating CONSTRAINT` (Primary keys and unique constraints generated)
  9. `pg_restore: creating FK CONSTRAINT` (Referential integrity constraints applied)
  10. `pg_restore: creating ACL` (Schema, table, and sequence privileges applied)
- **Exit Code:** `0` (Clean completion with 0 errors and 0 warnings).

---

## 3. Investigation of Errors, Warnings, and Variances

### 3.1 Syntax, DDL, and Constraint Errors
- **Errors Encountered:** `0`
- **Warnings Encountered:** `0`
- All foreign keys and table check constraints restored in correct topological dependency order without manual intervention.

### 3.2 Ownership Analysis
- **Source Database Objects (`canteendb`):** Owned by `postgres`.
- **Restored Database Objects (`canteendb_activity6_restore_test`):** Owned by `postgres`.
- In a production environment where objects are owned by `canteen_admin`, `pg_restore` requires that `canteen_admin` exists prior to restore, or `-O` (`--no-owner`) can be specified to reassign ownership to the connecting restore account.

### 3.3 Access Control & Permission Differences (Critical Security Finding)
A side-by-side catalog comparison between the source and restored databases revealed a key security variance:

```sql
SELECT datname, datacl FROM pg_database 
WHERE datname IN ('canteendb', 'canteendb_activity6_restore_test');
```

| Database | `pg_database.datacl` | Security Implication |
|---|---|---|
| `canteendb` (Source) | `{=Tc/postgres,postgres=CTc/postgres,canteen_app_grp=c/postgres,canteen_readonly_grp=c/postgres}` | Public access revoked; only explicit roles permitted. |
| `canteendb_activity6_restore_test` (Restored) | `NULL` (PostgreSQL Defaults) | Default public connect privileges active. |

**DBA Finding:**
Table-level ACLs (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) are stored in `pg_class.relacl` and are preserved in the dump. However, database-level privileges (`pg_database.datacl`) are cluster-level catalog properties. Consequently, a restored database requires explicit re-execution of `db-access-control/03-database-privileges.sql` to re-establish database-level access restrictions:
```sql
REVOKE ALL ON DATABASE canteendb_activity6_restore_test FROM PUBLIC;
GRANT CONNECT ON DATABASE canteendb_activity6_restore_test TO canteen_admin, canteen_app, canteen_readonly;
```

---

## 4. Preservation of Original Database

Throughout the execution of Phase 4, the original production database `canteendb` remained completely isolated:
- Zero DDL or DML statements were executed against `canteendb`.
- Catalog inspection confirmed `canteendb` table definitions and permissions remained identical to their pre-activity state.

---

## 5. Execution Screenshots & Evidence Artifacts

```
[SCREENSHOT PLACEHOLDER 6: Test Database Creation via createdb]
Caption: Execution of createdb canteendb_activity6_restore_test on port 5432.

[SCREENSHOT PLACEHOLDER 7: Full Archive Restoration via pg_restore --verbose]
Caption: Verbose output showing sequential creation of tables, sequences, constraints, and ACLs.

[SCREENSHOT PLACEHOLDER 8: Database ACL Comparison (Source vs. Restored)]
Caption: psql query comparing datacl between canteendb and canteendb_activity6_restore_test.
```

