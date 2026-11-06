# COMP 018 – Database Administration | Activity 6
## Phase 4: Database Restoration to Test Environment Report
**Restoration Target Database:** `grp00_habalgodb_activity6_restore_test`  
**Source Backup File:** `habalgo_activity6.dump`  
**Database Host:** `localhost:5432`  
**Database Superuser:** `postgres`  
**Restoration Timestamp:** 2026-11-06 17:20:38 PHT  
**Operating System:** Windows (x86_64)  
**PostgreSQL Version:** 18.6  
**Document Author:** Senior PostgreSQL Database Administrator (Student DBA)  

---

## 1. Objectives and Safety Protocol

In compliance with COMP 018 Activity 6 safety standards, the original database `grp00_habalgodb` was completely protected and left untouched. Restoration was directed into an isolated test database identified by the required standard suffix:
**`grp00_habalgodb_activity6_restore_test`**

### Pre-restoration Verification:
1. Checked for database name collision: Confirmed `grp00_habalgodb_activity6_restore_test` did not previously exist.
2. Verified original database status: `grp00_habalgodb` preserved in its original unmutated state.
3. Verified backup file checksum: SHA-256 matched `3CF5A86D91B9854F5D133737BB3ABD8459B99EE1A483C979840C3825518CA2E0`.

---

## 2. Test Database Provisioning and Restoration Execution

### Step 1: Provisioning the Isolated Test Database
```powershell
& "C:\Program Files\PostgreSQL\18\bin\createdb.exe" `
    -U postgres `
    -h localhost `
    -p 5432 `
    grp00_habalgodb_activity6_restore_test
```
- **Exit Code:** `0` (Success)
- **Database Created:** `grp00_habalgodb_activity6_restore_test`
- **Owner:** `postgres`

### Step 2: Executing Logical Archive Restoration
```powershell
& "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe" `
    -U postgres `
    -h localhost `
    -p 5432 `
    -d grp00_habalgodb_activity6_restore_test `
    "C:\Users\Matt\.gemini\antigravity\brain\70a3cb86-a366-40fd-a9d0-0fafa69e72d3\scratch\backups\habalgo_activity6.dump"
```
- **Exit Code:** `0` (Success)
- **Standard Error / Warnings:** None. Clean execution without error.

---

## 3. Post-Restoration Structural Verification

The test database was queried to verify the complete recreation of all application structures:

| Restored Object | Type | Owner | Status |
| :--- | :--- | :--- | :---: |
| `habalgo` | Schema | `postgres` | **RESTORED** |
| `habalgo.customer` | Table | `postgres` | **RESTORED** |
| `habalgo.driver` | Table | `postgres` | **RESTORED** |
| `habalgo.vehicle` | Table | `postgres` | **RESTORED** |
| `habalgo.driver_vehicle` | Table | `postgres` | **RESTORED** |
| `habalgo.location` | Table | `postgres` | **RESTORED** |
| `habalgo.booking` | Table | `postgres` | **RESTORED** |
| `habalgo.payment` | Table | `postgres` | **RESTORED** |
| `habalgo.rating_feedback` | Table | `postgres` | **RESTORED** |
| `7 Sequences` | Sequence Objects | `postgres` | **RESTORED** |
| `17 Indexes` | BTREE Indexes | `postgres` | **RESTORED** |
| `8 Foreign Keys` | Referential Constraints | `postgres` | **RESTORED** |

---

## 4. Ownership and Privilege Difference Analysis

- **Object Ownership:** All restored tables, sequences, and schemas maintain ownership under `postgres`, mirroring the source database.
- **Access Control Lists (ACLs):** The custom dump restored all explicit permissions:
  - `habalgo_admin`: Full CRUD and maintenance privileges (`arwdDxtm`).
  - `habalgo_app`: Application runtime privileges (`arw` - SELECT, INSERT, UPDATE).
  - `habalgo_auditor`: Read-only reporting privileges (`r` - SELECT only).
- **Cluster Role Dependencies:** Because the roles `habalgo_admin`, `habalgo_app`, and `habalgo_auditor` already existed at the cluster level, all ACL assignments resolved with zero warnings.

---

## 5. Phase 4 Conclusion

The restoration from the custom archive `habalgo_activity6.dump` into `grp00_habalgodb_activity6_restore_test` was **100% SUCCESSFUL**. Zero errors or warnings were encountered. The original database remained pristine.

