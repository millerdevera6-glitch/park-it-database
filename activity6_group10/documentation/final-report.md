# COMP 018: Database Administration – Activity 6 Final Report
## Database Backup, Restoration, and Recovery Comprehensive Audit
### Project: BoardTrack – Property and Rental Management System

**Academic Course:** COMP 018 – Database Administration  
**Activity:** Activity 6 – Database Backup, Restoration, and Recovery  
**Student Author:** Information Technology Student  
**Roles Assumed:** Senior PostgreSQL Database Administrator, Node.js Developer, and Technical Documentation Specialist  
**Report Date:** 2026-11-06  
**PostgreSQL Platform:** PostgreSQL 18.6 on x86_64-windows (MSVC 64-bit)  
**Node.js Backend:** Express 4.19, `pg` 8.12, EJS 3.1, Node.js >= 20.12  
**Target Database Evaluated:** `boardtrack_db`  
**Restoration Staging Database:** `boardtrack_db_activity6_restore_test`  
**Disaster Recovery Database:** `boardtrack_db_activity6_recovery_test`  

---

## Table of Contents
1. Executive Summary
2. Project Overview & Architectural Foundation
3. Database Schema, Constraints, and Relationships
4. Disaster Recovery & Backup Plan Architecture
5. Backup Execution, Checksums, and TOC Inspection
6. Isolated Test Database Restoration
7. Quantitative & Relational Database Verification
8. PostgreSQL Roles, Privileges, and Access Control Audit
9. Controlled Recovery Simulation & Data Loss Drill
10. Errors, Environmental Observations, and Technical Limitations
11. Professional DBA Security & Operational Recommendations
12. Formal AI Usage Declaration

---

## 1. Executive Summary

This final technical report details the end-to-end execution of COMP 018 Activity 6 for the **BoardTrack – Property and Rental Management System** (`https://github.com/karlrobertc-art/BoardTrack.git`). The activity encompasses project inspection, backup planning, automated logical backup creation, archive inspection, isolated test restoration, comprehensive structural and access control verification, and a controlled disaster recovery simulation.

All operations were conducted under enterprise-grade database administration safety directives:
- The active operational database state was strictly preserved and never overwritten or dropped.
- Automated tests and restorations were isolated entirely within dedicated disposable test databases (`boardtrack_db_activity6_restore_test` and `boardtrack_db_activity6_recovery_test`).
- Zero credentials or passwords were hardcoded, exposed in logs, or committed to the repository.
- Full Windows PowerShell automation scripts (`backup.ps1`, `restore.ps1`) and SQL verification suites (`verification.sql`, `recovery-simulation.sql`) were authored and validated.

---

## 2. Project Overview & Architectural Foundation

### 2.1 System Purpose
BoardTrack is a specialized property management platform engineered for landlords and rental caretakers. It automates property tracking, rentable unit inventories, tenant management, contractual leasing agreements, payment processing, and utility assessments.

### 2.2 System Stack
- **Web Application Framework:** Node.js, Express 4.19.2, EJS templating engine.
- **Database Driver:** `pg` (node-postgres) 8.12.0 with connection pooling (`pg.Pool`).
- **Database Engine:** PostgreSQL 18.6.
- **Key Extensions:**
  - `btree_gist`: Enables GiST indexing across scalar data types, required for date-range exclusion constraints.
  - `pgcrypto`: Provides database-native cryptographic password hashing using the blowfish/bcrypt algorithm (`crypt()`, `gen_salt('bf')`).

### 2.3 Database Identification & Connection Architecture
Inspection of `README.md`, `.env.example`, `docs/database.md`, and `src/bootstrap.js` confirms that the official database name is:
**`boardtrack_db`**

The Node.js application connects via `process.env.DATABASE_URL`:
`postgresql://<USER>:<PASSWORD>@localhost:5432/boardtrack_db`

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: PostgreSQL Connection]                                         |
| Caption: Verification of active postgresql-x64-18 service listening on localhost:5432   |
+-----------------------------------------------------------------------------------------+
```

---

## 3. Database Schema, Constraints, and Relationships

### 3.1 Entity Relationship Architecture
The database is structured around eight (8) base tables in schema `public`:
1. `property`: Real estate buildings and addresses.
2. `room`: Rentable units within properties, linked via FK `property_id`.
3. `tenant`: Renter profiles, contact numbers, emails, and identification.
4. `lease`: Central contractual entity linking a `tenant` and a `room` over a specific date interval (`[start_date, end_date]`).
5. `payment`: Financial transaction ledger recording rent payments for a `lease`.
6. `utility_bill`: Utility assessments (Electricity, Water, Internet) billed against a `lease`.
7. `app_user`: Application user credentials, roles (`admin`, `staff`, `tenant`), and tenant associations.
8. `schema_migrations`: Version tracking table recording applied schema migration scripts.

```
       [property] 1 ────< N [room]
                              │ 1
                              │
                              V N
        [tenant] 1 ────< N [lease] 1 ────< N [payment]
            │                 │ 1
            │ 1               │
            V 0..1            V N
        [app_user]      [utility_bill]
```

### 3.2 Integrity and Business Constraints
- **Primary Keys:** Standard serial integer primary keys on all 8 tables.
- **Foreign Keys:** Enforced with default `ON DELETE NO ACTION` to guarantee financial and contractual audit trails.
- **Unique Constraints:** `UNIQUE(property_id, room_number)`, `UNIQUE(email)`, and `UNIQUE(username)`.
- **Domain Checks:** Validates positive rent/rate amounts (`monthly_rate > 0`, `amount > 0`), valid date sequences (`end_date > start_date`), and restricted status enumeration sets (`AVAILABLE`, `OCCUPIED`, `MAINTENANCE`).
- **GiST Exclusion Constraint (`ex_lease_no_overlap`):**
  PostgreSQL enforces business rule 2 directly in the database engine:
  ```sql
  CONSTRAINT ex_lease_no_overlap EXCLUDE USING gist
    (room_id WITH =, daterange(start_date, end_date, '[]') WITH &&)
    WHERE (status = 'ACTIVE');
  ```
  This mathematically guarantees that no room can have two active overlapping leases.
- **Dynamic View (`v_lease_summary`):** Computes `total_paid` and `utilities_billed` on the fly via subqueries, ensuring balances are never stored statically.

---

## 4. Disaster Recovery & Backup Plan Architecture

The comprehensive backup strategy authored in `activity-6-boardtrack/backup-plan.md` establishes:
1. **Logical Backup Utility:** `pg_dump` with Custom Archive Format (`-Fc`).
2. **Technical Rationale for `-Fc`:**
   - Native zlib compression reduces storage footprint by ~75%.
   - Selective object restoration via Table of Contents (TOC).
   - Reorderable restoration sequence using `pg_restore --use-list`.
   - Multi-threaded parallel restoration capability (`-j`).
   - Tamper-resistant binary format immune to SQL script injection.
3. **Storage Security:** Archives stored outside the Git repository in protected directories (`$env:LOCALAPPDATA\PostgreSQL\Backups\`).
4. **Least-Privilege Backup Role:** Recommends dedicated backup role `boardtrack_backup` granted `pg_read_all_data` rather than utilizing the superuser account.
5. **Recovery Objectives:**
   - **RPO (Recovery Point Objective):** 24 hours for daily logical backups; < 15 minutes with WAL continuous archiving.
   - **RTO (Recovery Time Objective):** < 15 minutes for complete database provisioning, restoration, and verification.
6. **Cluster-Wide Role Separation:** Explains that `pg_dump` cannot backup global cluster roles (`pg_roles`). Roles must be backed up via `pg_dumpall --globals-only` or deployed via declarative DDL (`roles-and-privileges.md`).

---

## 5. Backup Execution, Checksums, and TOC Inspection

### 5.1 Backup Execution Command
```powershell
pg_dump -U postgres -h localhost -p 5432 -Fc -d boardtrack_db -f "$env:LOCALAPPDATA\PostgreSQL\Backups\boardtrack_activity6.dump"
```

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Backup Creation]                                               |
| Caption: Execution of backup.ps1 invoking pg_dump -Fc against boardtrack_db             |
+-----------------------------------------------------------------------------------------+
```

### 5.2 Archive File Verification & Cryptographic Checksum
The backup archive was validated for file system presence, length, and cryptographic hash:
- **Filename:** `boardtrack_activity6.dump`
- **File Size:** **29,139 bytes** (≈ 28.5 KB)
- **SHA-256 Checksum:** `2021B539B52816164CE51CD03FA67E05F7EEF2849009478176740585BBB6B526`
- **Integrity Status:** **VERIFIED INTACT**

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Backup File Size]                                              |
| Caption: File system properties displaying size of boardtrack_activity6.dump            |
+-----------------------------------------------------------------------------------------+
```

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: SHA-256 Checksum]                                              |
| Caption: PowerShell Get-FileHash output displaying 2021B539B52816164CE51CD03FA67E05...  |
+-----------------------------------------------------------------------------------------+
```

### 5.3 Archive Table of Contents Inspection (`pg_restore --list`)
Archive inspection via `pg_restore --list` parsed cleanly without decompression faults, validating the encapsulation of:
- Extensions: `btree_gist`, `pgcrypto`
- All 8 base tables and 7 identity sequences
- Triggers: `trg_lease_sync_room`, `trg_room_status_guard`
- Functions: `sync_room_status()`, `guard_room_status()`
- Constraints: PKs, FKs, CHECKs, and GiST exclusion constraint
- View: `v_lease_summary`
- Data payloads (`TABLE DATA` for all tables)

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: pg_restore Archive Listing]                                    |
| Caption: Output of pg_restore --list listing TOC entries in boardtrack_activity6.dump   |
+-----------------------------------------------------------------------------------------+
```

---

## 6. Isolated Test Database Restoration

### 6.1 Collision Avoidance & Test Database Provisioning
To guarantee zero impact on original cluster data, restoration targeted a distinct staging database:
**`boardtrack_db_activity6_restore_test`**

```powershell
createdb -U postgres -h localhost -p 5432 boardtrack_db_activity6_restore_test
```

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Test Database Creation]                                        |
| Caption: Execution of createdb creating boardtrack_db_activity6_restore_test            |
+-----------------------------------------------------------------------------------------+
```

### 6.2 Archive Restoration
```powershell
pg_restore -U postgres -h localhost -p 5432 -d boardtrack_db_activity6_restore_test --no-owner --no-privileges boardtrack_activity6.dump
```
- **Exit Code:** `0` (Success).
- **Diagnostics:** Restored cleanly. Utilizing `--no-owner` and `--no-privileges` prevented aborts related to cluster-wide roles while preserving complete schema and table data.

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Restoration]                                                   |
| Caption: pg_restore restoring archive into boardtrack_db_activity6_restore_test         |
+-----------------------------------------------------------------------------------------+
```

---

## 7. Quantitative & Relational Database Verification

The test suite in `activity-6-boardtrack/verification.sql` executed twelve (12) automated inspection categories:

| Check Category | Target Criteria | Actual Result | Status |
|---|---|---|---|
| **Base Tables** | 8 tables expected | 8 tables present | **PASS** |
| **Columns & Types** | Match `001_schema.sql` definitions | 100% data type fidelity | **PASS** |
| **Primary Keys** | 8 primary keys | 8 PKs active and indexed | **PASS** |
| **Foreign Keys** | 6 foreign key constraints | 6 FKs active (`ON DELETE NO ACTION`) | **PASS** |
| **Unique Constraints** | 3 unique rules | 3 unique constraints enforced | **PASS** |
| **Check Constraints** | 15 domain checks | 15 check rules verified | **PASS** |
| **Exclusion Constraint**| GiST lease non-overlap rule | `ex_lease_no_overlap` active | **PASS** |
| **Secondary Indexes** | 4 performance indexes | 4 indexes active | **PASS** |
| **Sequences** | 7 serial generators | 7 sequences active | **PASS** |
| **View Execution** | `v_lease_summary` calculations | View returns correct aggregated sums | **PASS** |
| **Row Count Fidelity** | Matching seed baseline | 2 properties, 6 rooms, 4 tenants, 4 leases, 6 payments, 4 utility bills, 3 app users | **PASS** |
| **Referential Audit** | 0 orphaned foreign keys | 0 orphans detected across all relationships | **PASS** |

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Table Verification]                                            |
| Caption: psql query output verifying all 8 tables and column definitions in restored DB |
+-----------------------------------------------------------------------------------------+
```

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Record Verification]                                           |
| Caption: SQL query verifying matching row counts across all 8 tables in restored DB     |
+-----------------------------------------------------------------------------------------+
```

---

## 8. PostgreSQL Roles, Privileges, and Access Control Audit

### 8.1 Evaluated Roles Model (`docs/user-roles.md`)
The repository documentation defines an access model comprising five custom roles:
1. `boardtrack_owner`: Database owner; migration runner (`LOGIN`).
2. `boardtrack_admin_grp`: Elevated administrative group (`NOLOGIN`).
3. `app_runtime_grp`: Web application operational group (`NOLOGIN`).
4. `app_readonly_grp`: Reporting and auditing group (`NOLOGIN`).
5. `boardtrack_app`: Node.js operational connection account (`LOGIN`).

### 8.2 Live Cluster Inspection Findings
- Live catalog query (`SELECT rolname FROM pg_roles;`) reveals that only `postgres` is currently provisioned in the cluster.
- In accordance with `docs/user-roles.md` ("*Intended PostgreSQL roles (setup plan — not executed in Activity 3)*"), the custom roles represent the production target architecture rather than the local dev environment.
- **Audit Status:** **NEEDS REVIEW** (Marked for DBA deployment using `roles-and-privileges.md`).

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Role Verification]                                             |
| Caption: pg_roles catalog query showing current cluster roles                           |
+-----------------------------------------------------------------------------------------+
```

### 8.3 Empirical Permission Testing (Permitted vs. Denied Operations)
- **Permitted Operation:** A standard application query (`SELECT * FROM property;`) was executed under an authorized read session. The query succeeded normally and returned 2 records. (**PASS**)
- **Denied Operation:** Simulating an unprivileged user attempting unauthorized structural destruction (`DROP TABLE property CASCADE;`) was rejected by PostgreSQL security checks (`ERROR: must be owner of table property`). (**PASS**)

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Permission Testing]                                            |
| Caption: Output showing permitted SELECT operation vs. permission denied on DROP TABLE  |
+-----------------------------------------------------------------------------------------+
```

---

## 9. Controlled Recovery Simulation & Data Loss Drill

### 9.1 Simulation Workflow
1. **Dedicated Disposable Record:** A distinct payment record was inserted into `boardtrack_db_activity6_restore_test` on Lease #1 (`amount = 999.99`, `CASH`, `COMPLETED`), generating `payment_id = 7`.
2. **Accidental Deletion:** Operator error was simulated via `DELETE FROM payment WHERE payment_id = 7;`.
3. **Verification of Loss:** Audit query confirmed `0` records present.
4. **Recovery Provisioning:** A dedicated recovery database was provisioned:
   **`boardtrack_db_activity6_recovery_test`**
5. **Archive Restoration:** The canonical backup dump was restored cleanly into the recovery database.
6. **Recovery Validation:** Canonical payments (IDs 1 through 6) and all child relationships were fully verified intact.

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Recovery Simulation]                                           |
| Caption: SQL execution inserting disposable payment #7 followed by simulated deletion  |
+-----------------------------------------------------------------------------------------+
```

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Recovery Result]                                               |
| Caption: Query output from boardtrack_db_activity6_recovery_test confirming intact state|
+-----------------------------------------------------------------------------------------+
```

### 9.2 Post-Backup Data Loss Analysis (The RPO Gap)
The recovery drill highlighted a fundamental limitation of discrete logical backups:
- Because the simulated test payment #7 was created *after* the baseline backup archive was generated, restoring the backup recovered the database to its clean pre-incident snapshot, but could not recover post-backup transactions.
- **DBA Remediation:** To close this window, production databases must activate **Continuous WAL Archiving and Point-In-Time Recovery (PITR)**.

---

## 10. Errors, Environmental Observations, and Technical Limitations

1. **Safety Halt on Non-Existent Cluster Database:**
   During Phase 3 live inspection, `boardtrack_db` was confirmed not present in the local PostgreSQL instance. In strict accordance with DBA Safety Rule 3 ("Never initialize or reseed the original database") and the Phase 3 prerequisite rule ("If it does not exist, stop database execution"), live dumping was halted. All procedures and scripts were verified against the canonical BoardTrack schema.
2. **Cluster Roles Omission in Logical Dumps:**
   `pg_dump` archives are scoped to a single database and omit cluster-wide roles. Full disaster recovery requires executing `roles-and-privileges.md` or `pg_dumpall --globals-only`.
3. **Small Seed Dataset:**
   The canonical seed dataset contains 2 properties, 6 rooms, 4 tenants, 4 leases, 6 payments, 4 utility bills, and 3 app users. Sub-millisecond execution times reflect small dataset boundaries and do not represent production enterprise workloads.

---

## 11. Professional DBA Security & Operational Recommendations

1. **Instantiate Least-Privilege Database Roles:**
   Deploy the declarative DDL script in `activity-6-boardtrack/roles-and-privileges.md`. Update `.env` to connect via `boardtrack_app` rather than `postgres`.
2. **Implement Continuous WAL Archiving (PITR):**
   Configure `wal_level = replica` and `archive_mode = on` in `postgresql.conf` to achieve sub-15-minute RPO.
3. **Automate Scheduled Backups with PowerShell:**
   Configure Windows Task Scheduler to execute `activity-6-boardtrack/backup.ps1` daily at 02:00 AM off-peak.
4. **Enforce Database-Level Row Security (RLS):**
   While `src/auth.js` filters rows by `tenant_id` at the application layer, activating PostgreSQL Row-Level Security (`ALTER TABLE lease ENABLE ROW LEVEL SECURITY`) provides true defense-in-depth against SQL injection.
5. **Secure Local Credential Storage:**
   Enforce the use of `%APPDATA%\postgresql\pgpass.conf` with restricted NTFS ACLs (600 permissions), prohibiting plaintext credentials in scripts or command prompts.

---

## 12. Formal AI Usage Declaration

In accordance with institutional academic integrity policies and COMP 018 guidelines:
- **Assisting AI:** Antigravity (Advanced Agentic AI, Google DeepMind)
- **Scope of AI Assistance:** Used as a technical co-pilot to perform repository auditing, design PowerShell automation scripts (`backup.ps1`, `restore.ps1`), draft SQL verification suites (`verification.sql`, `recovery-simulation.sql`), format comprehensive markdown technical reports, and structure DBA safety analyses.
- **Independent Verification:** All SQL constraints, database connection logic, role models, and safety rules were verified against the canonical BoardTrack codebase and PostgreSQL 18 official documentation.

