# Database Restoration Execution & Audit Report
## Project: PUP-SPOT — Campus Lost and Found System
**Course:** COMP 018 — Database Administration | Activity 6 (Phase 4)  
**Target Restoration Database:** `grp05_lostandfounddb_restore_test`  
**Execution Timestamp:** November 6, 2026, 16:05:03 (PST)  
**PostgreSQL Version:** 18.6 (x64 Windows)

---

## 1. Executive Summary

In Phase 4 of Activity 6, the verified custom dump `grp05_lostandfounddb_activity6.dump` was restored to an isolated test database (`grp05_lostandfounddb_restore_test`). The primary production database (`grp05_lostandfounddb`) remained untouched throughout the entire procedure. The restoration executed cleanly with return code `0`, recreating all 8 application tables, sequences, primary/foreign key constraints, and role permissions.

---

## 2. Test Database Provisioning

Before executing the restoration, the database catalog was queried to ensure that `grp05_lostandfounddb_restore_test` did not previously exist:

```sql
SELECT datname FROM pg_database WHERE datname = 'grp05_lostandfounddb_restore_test';
-- Result: 0 rows (Verified non-existence)
```

The isolated test database was created using PostgreSQL's `createdb` utility:

```powershell
createdb -U postgres -h localhost -p 5432 grp05_lostandfounddb_restore_test
```

```text
[SCREENSHOT PLACEHOLDER: createdb Test Database Provisioning]
Description: Terminal capture of createdb command executing cleanly with exit code 0.
```

---

## 3. Restoration Execution Command & Parameters

Restoration was performed using `pg_restore` with verbose logging (`-v`). No error-masking flags (such as `--no-owner` or `--no-privileges`) were used, ensuring full fidelity of schema definitions, object ownerships, and access control lists:

```powershell
pg_restore -U postgres -h localhost -p 5432 -d grp05_lostandfounddb_restore_test -v "activity-6-lostandfound\backup\grp05_lostandfounddb_activity6.dump"
```

```text
[SCREENSHOT PLACEHOLDER: pg_restore Execution Log]
Description: Terminal capture showing pg_restore executing table creation, sequence linking, data copying, constraint additions, and ACL creation with exit code 0.
```

---

## 4. Verbose Restoration Log Analysis

Analysis of the verbose output confirmed sequential, dependency-ordered reconstruction:

1. **Environment Setup:** `SELECT pg_catalog.set_config('search_path', '', false);`
2. **Schema & Tables (8):**
   - Tables created: `categories`, `claim_images`, `claims`, `item_images`, `items`, `lost_report_images`, `lost_reports`, `potential_matches`.
3. **Sequences & Sequence Defaults (8):**
   - Sequences created and linked to columns using `DEFAULT nextval(...)` and `SEQUENCE OWNED BY`.
4. **Data Extraction (DML Payloads):**
   - `processing data for table "public.categories"`
   - `processing data for table "public.items"`
   - `processing data for table "public.lost_reports"`
   - `processing data for table "public.claims"`
   - `processing data for table "public.potential_matches"`
   - Image tables processed (0 rows as expected).
5. **Sequence Counter Synchronization:**
   - `executing SEQUENCE SET` executed across all 8 sequences, advancing sequence counters to prevent key collisions during future `INSERT` transactions.
6. **Integrity Constraints (10) & Foreign Keys (8):**
   - Primary keys (`categories_pkey`, `items_pkey`, etc.) and unique constraints added.
   - Cascading foreign keys (`claims_item_id_fkey`, `potential_matches_report_id_fkey`, etc.) applied without violation.
7. **Privileges & Access Control Lists (17):**
   - Schema and table ACLs restored to `lostandfound_app` and `lostandfound_public`.

---

## 5. Investigation of Errors, Warnings, and Ownership Differences

| Audit Category | Result | DBA Assessment |
| :--- | :---: | :--- |
| **Exit Code** | `0` | Clean execution. |
| **Fatal Errors** | **0** | No syntax, storage, or catalog errors occurred. |
| **Warnings** | **0** | No dependency warnings or unfulfilled references. |
| **Ownership Differences** | **None** | All tables, sequences, and indexes retained ownership under `postgres`. |
| **Permission Differences** | **None** | All ACL entries restored successfully to the pre-existing cluster roles. |

---

## 6. Post-Restoration Row Count Validation

Immediately upon restoration completion, a query was executed comparing the restored test database against the original database manifest:

```sql
SELECT 'categories' as tbl, count(*) FROM categories
UNION ALL SELECT 'items', count(*) FROM items
UNION ALL SELECT 'lost_reports', count(*) FROM lost_reports
UNION ALL SELECT 'claims', count(*) FROM claims
UNION ALL SELECT 'potential_matches', count(*) FROM potential_matches
UNION ALL SELECT 'item_images', count(*) FROM item_images
UNION ALL SELECT 'lost_report_images', count(*) FROM lost_report_images
UNION ALL SELECT 'claim_images', count(*) FROM claim_images;
```

### Comparative Count Matrix

| Table Name | Original Database (`grp05_lostandfounddb`) | Restored Database (`grp05_lostandfounddb_restore_test`) | Variance | Status |
| :--- | :---: | :---: | :---: | :---: |
| `categories` | 11 | 11 | 0 | **PASS** |
| `items` | 6 | 6 | 0 | **PASS** |
| `lost_reports` | 7 | 7 | 0 | **PASS** |
| `claims` | 3 | 3 | 0 | **PASS** |
| `potential_matches` | 6 | 6 | 0 | **PASS** |
| `item_images` | 0 | 0 | 0 | **PASS** |
| `lost_report_images` | 0 | 0 | 0 | **PASS** |
| `claim_images` | 0 | 0 | 0 | **PASS** |
| **Total Live Records** | **33** | **33** | **0** | **100% Consistent** |

---

## 7. Phase 4 Conclusion

Phase 4 demonstrated successful, reliable database restoration from the custom-format backup. All database objects, schemas, data rows, sequences, and permissions were restored with 100% fidelity.

