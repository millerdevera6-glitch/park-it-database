# BoardTrack Database Backup and Disaster Recovery Plan

**Project:** BoardTrack — Boarding House & Rental Management System  
**Target Database:** `boardtrack_db`  
**Database Management System:** PostgreSQL 18.6 (compatible with 13+)  
**Course:** COMP 018 — Database Administration  
**Activity:** Activity 6: Database Backup, Restoration, and Recovery  
**Document Author:** Senior PostgreSQL Database Administrator  
**Version:** 1.0 (Production / Academic Standard)  
**Date:** 2026-11-06  

---

## 1. Overview and Objectives

This document establishes the official enterprise backup, restoration, and disaster recovery policy for the **BoardTrack** rental management system. The primary goal is to protect institutional property data, lease contracts, tenant payment audits, and user credentials against catastrophic hardware failure, administrative error, data corruption, and malicious compromise, while guaranteeing high data integrity, minimal downtime, and strict adherence to the Principle of Least Privilege.

---

## 2. Database and Objects in Backup Scope

The backup plan encompasses all logical and relational objects within the target database `boardtrack_db`:

### 2.1 Logical Scope
* **Target Database:** `boardtrack_db`
* **Target Schema:** `public`
* **Extensions:** `btree_gist` (exclusion constraint support), `pgcrypto` (cryptographic password hashing).

### 2.2 Relational Tables (Base Tables)
1. `property`: Master records for rental boarding houses and buildings.
2. `room`: Rental units, room numbers, monthly base rates, and occupancy statuses.
3. `tenant`: Tenant personal profiles, emergency contact numbers, email addresses, and valid government ID references.
4. `lease`: Contractual binding between tenants and rooms, including contract validity periods, contractual rent, move-out timestamps, and exclusion constraints.
5. `payment`: Audited financial records of rent collections, payment dates, payment methods (`CASH`, `GCASH`, `BANK_TRANSFER`), and settlement statuses.
6. `utility_bill`: Recurring consumption bills for electricity, water, and internet keyed to active leases.
7. `app_user`: System logins, bcrypt-hashed credentials, application roles (`admin`, `staff`, `tenant`), active flags, and tenant associations.
8. `schema_migrations`: Administrative tracking table recording applied database migration versioning.

### 2.3 Programmable and Auxiliary Objects
* **Constraints:** Primary keys, foreign key constraints (`ON DELETE NO ACTION`), unique constraints, check constraints, and the GiST exclusion constraint (`ex_lease_no_overlap`).
* **Indexes:** Secondary B-tree indexes (`idx_lease_room`, `idx_lease_tenant`, `idx_payment_lease`, `idx_utility_lease`) and constraint-enforcing indexes.
* **Sequences:** Auto-incrementing sequences associated with serial primary keys (`*_seq`).
* **Triggers & Functions:** 
  - `sync_room_status()` and `trg_lease_sync_room` (automatic occupancy synchronization).
  - `guard_room_status()` and `trg_room_status_guard` (occupancy constraint enforcement).
* **Views:** `v_lease_summary` (on-the-fly computation of lease balances, paid totals, and utility billing).

---

## 3. Logical Backup Method

The approved logical backup mechanism for `boardtrack_db` is **PostgreSQL `pg_dump`**. 

`pg_dump` extracts a consistent, point-in-time snapshot of the database while allowing concurrent read and write operations. Because `pg_dump` utilizes PostgreSQL's Multi-Version Concurrency Control (MVCC), it does not acquire exclusive read locks on business tables, ensuring zero downtime and no disruption to tenant portal queries or caretaker rent encoding.

---

## 4. Technical Justification for Custom Archive Format (`-Fc`)

PostgreSQL provides multiple output formats (`plain` text SQL `-Fp`, `tar` `-Ft`, `directory` `-Fd`, and `custom` `-Fc`). The **Custom Archive Format (`-Fc`)** is explicitly designated as the mandatory standard for BoardTrack based on the following DBA criteria:

| Evaluation Factor | Plain SQL (`-Fp`) | Custom Archive (`-Fc`) | Justification for BoardTrack |
|---|---|---|---|
| **Compression** | None (uncompressed text) | Built-in zlib compression | Drastically minimizes disk storage footprint and reduces I/O transfer time across local drives or backup networks. |
| **Restoration Flexibility** | All-or-nothing sequential text execution | Selective table, data-only, or schema-only restoration | Enables fine-grained granular recovery. Individual corrupted tables (e.g., `payment`) can be restored without wiping the entire database. |
| **Object Reordering** | Fixed linear SQL text ordering | Dynamic dependency-aware reordering via TOC | Eliminates foreign-key and dependency restoration errors during multithreaded recovery. |
| **TOC Inspection** | Must parse massive text files | Built-in inspection via `pg_restore --list` | Allows instantaneous archive catalog inspection, integrity verification, and metadata auditing prior to restore. |
| **Parallel Restoration** | Single-threaded only (`-j` unsupported) | Supports parallel multithreading (`-j N`) | Allows multi-core processors to restore tables and build indexes concurrently, slashing RTO. |
| **Security & Safety** | Vulnerable to SQL parsing injection | Binary serialized format | Protects against text encoding corruption and unvetted SQL script tampering. |

---

## 5. Protected Backup Storage Architecture

All database backups must be stored in an isolated, secure filesystem directory outside the source code repository:

* **Primary Designated Backup Directory:**  
  `C:\PostgreSQL\backups\boardtrack\` (Windows standard secure administrative storage) or  
  `activity-6-boardtrack/backups/` *(Strictly ignored in `.gitignore`)*.
* **Access Control & Permissions (NTFS ACLs):**
  - **SYSTEM & PostgreSQL Service Account (`NT AUTHORITY\NetworkService`):** Full Control.
  - **Backup Administrators / DBA Group:** Read / Write / Execute.
  - **Standard Users / Web Application Runtime (`boardtrack_app`):** **NO ACCESS (Deny All).** The web application runtime must never possess read or write permissions over backup dump files.
* **Storage Isolation Rule:** Under no circumstances may `.dump`, `.backup`, or `.tar` files be committed to Git or exposed within web server document roots (`public/`).

---

## 6. Authorized Backup Accounts and Least Privilege

In compliance with the Principle of Least Privilege:
1. **Routine Automated Backups:** Executed by a dedicated non-superuser backup role:
   - Role: `boardtrack_backup`
   - Attributes: `LOGIN`, `NOSUPERUSER`, `NOCREATEDB`, `NOCREATEROLE`
   - Privileges: Membership in PostgreSQL built-in read-all role `pg_read_all_data` (PostgreSQL 14+), or explicit `GRANT SELECT ON ALL TABLES IN SCHEMA public TO boardtrack_backup;` and `GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO boardtrack_backup;`.
2. **Disaster Recovery & Cluster Provisioning:** Carried out by the database owner `boardtrack_owner` or cluster administrator `postgres`.
3. **Application Credentials Exclusion:** The web application account (`boardtrack_app`) is strictly prohibited from executing backup and restore routines.

---

## 7. Backup Verification Procedure

A backup cannot be considered valid until it has passed formal multi-stage verification:

```
[ Step 1: Process Exit Code ] -> [ Step 2: Non-Zero File Size ] -> [ Step 3: SHA-256 Hash ] -> [ Step 4: Archive TOC Audit ] -> [ Step 5: Sandbox Restore ]
```

1. **Process Exit Status Verification:** Verify that `pg_dump` terminated with return code `0` (`$LASTEXITCODE -eq 0`). Any non-zero exit code indicates an immediate fatal failure.
2. **File Size and Existence Verification:** Confirm the dump file exists on disk and has a non-zero byte size (`FileInfo.Length > 0`).
3. **Cryptographic Checksumming:** Compute and record the cryptographic SHA-256 hash immediately after creation using PowerShell `Get-FileHash -Algorithm SHA256`. The checksum is written to a tamper-evident audit log (`checksums.sha256`) to guarantee integrity against bit rot or tampering.
4. **Table-of-Contents (TOC) Inspection:** Execute `pg_restore --list <dumpfile>` to parse the archive header and confirm that all 7 business tables, constraints, triggers, and views are present and readable.
5. **Periodic Sandbox Restoration:** Execute weekly automated restorations into an isolated test database (`boardtrack_db_verify_sandbox`) and execute automated row-count and foreign-key integrity checks.

---

## 8. Proposed Backup Schedule

| Frequency | Timing / Window | Scope & Method | Tooling | Retention Period |
|---|---|---|---|---|
| **Daily Full Backup** | 02:00 AM PHT (Low-traffic maintenance window) | Full logical backup (`-Fc`) of `boardtrack_db` | `backup.ps1` via Windows Task Scheduler | 14 Days |
| **Weekly Full Backup** | Sunday 03:00 AM PHT | Full logical backup (`-Fc`) + Globals export | Automated Script | 8 Weeks |
| **Monthly Archive** | 1st day of month 04:00 AM PHT | Full logical backup (`-Fc`) + Cryptographic audit | Long-term Archive | 12 Months |
| **Annual Compliance** | December 31, 11:00 PM PHT | Full snapshot + System catalog dump | Encrypted Vault | 7 Years |

---

## 9. Data Retention Policy (3-2-1 Strategy)

BoardTrack enforces the industry-standard **3-2-1 Backup Strategy**:
* **3 Copies of Data:** One live production database, one primary on-site backup copy, and one off-site secondary copy.
* **2 Different Storage Media:** On-site solid-state storage (NVMe/SSD) and isolated network/cloud object storage (e.g., AWS S3 with Object Lock or secure SFTP).
* **1 Copy Off-Site:** Encrypted and geo-redundantly separated from the physical host to survive local hardware or environmental failure.

### Grandfather-Father-Son (GFS) Rotation Schedule:
* **Son (Daily):** 14 daily incrementals/snapshots retained.
* **Father (Weekly):** 8 weekly snapshots retained.
* **Grandfather (Monthly):** 12 monthly archives retained.

---

## 10. Recovery Objectives (RPO and RTO)

### 10.1 Recovery Point Objective (RPO)
* **Definition:** The maximum acceptable age of data that must be recovered from backup storage for normal operations to resume after an incident (maximum allowable data loss duration).
* **Logical Backup Baseline:** **RPO = 24 Hours.** (Maximum possible data loss equals transactions entered since 02:00 AM daily backup).
* **Production Enhanced Target (with Continuous WAL Archiving):** **RPO $\le$ 5 Minutes.**

### 10.2 Recovery Time Objective (RTO)
* **Definition:** The maximum acceptable duration of time that a system can be offline after an incident before restoration is complete and operations resume.
* **Standard Disaster Recovery Target:** **RTO < 30 Minutes.**
  - Service spin-up & environment check: 5 minutes.
  - Sandbox test database recreation: 2 minutes.
  - Multi-threaded `pg_restore` (-j 4): 3 minutes.
  - Post-restore catalog and relationship verification: 10 minutes.
  - Web connection validation: 5 minutes.

---

## 11. Cluster-Wide Nature of PostgreSQL Roles and Recreation Procedure

### 11.1 Fundamental Architectural Constraint
> **CRITICAL POSTGRESQL ARCHITECTURAL PRINCIPLE:**  
> In PostgreSQL, **roles, users, and global privileges are cluster-wide database objects** stored in shared system catalogs (`pg_authid`, `pg_roles`, `pg_auth_members`). They **DO NOT** belong to any single individual database.
>
> Consequently, running `pg_dump -Fc -d boardtrack_db` **DOES NOT** and **CANNOT** capture PostgreSQL user accounts, password hashes, or cluster group memberships. A custom-format backup archive only stores object ownership metadata (the *name* of the owning role). If a backup archive is restored into a new PostgreSQL cluster where those roles do not yet exist, `pg_restore` will emit fatal role warnings, and restored tables will fall back to the ownership of the connecting superuser!

### 11.2 Cluster Globals Backup Command
To guarantee total disaster recovery from bare metal, global cluster roles must be exported separately using `pg_dumpall`:
```bash
pg_dumpall -U postgres -h localhost -p 5432 --globals-only -f globals_backup.sql
```

### 11.3 Independent Role Provisioning DDL
In the absence of a global dump, the 5 BoardTrack roles must be pre-provisioned prior to restoration using the following idempotent DDL script:

```sql
-- ============================================================================
-- BoardTrack Role and Privilege Recreation Script (Pre-Restoration DDL)
-- Must be executed by cluster superuser (postgres) before running pg_restore
-- ============================================================================

DO $$
BEGIN
    -- 1. boardtrack_owner (Database owner and migration executor)
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'boardtrack_owner') THEN
        CREATE ROLE boardtrack_owner WITH LOGIN CREATEDB;
    END IF;

    -- 2. boardtrack_admin_grp (Elevated administrative group, no superuser)
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'boardtrack_admin_grp') THEN
        CREATE ROLE boardtrack_admin_grp WITH NOLOGIN;
    END IF;

    -- 3. app_runtime_grp (Web runtime operational group)
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_runtime_grp') THEN
        CREATE ROLE app_runtime_grp WITH NOLOGIN;
    END IF;

    -- 4. app_readonly_grp (Reporting and tenant audit group)
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_readonly_grp') THEN
        CREATE ROLE app_readonly_grp WITH NOLOGIN;
    END IF;

    -- 5. boardtrack_app (Web application runtime login account)
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'boardtrack_app') THEN
        CREATE ROLE boardtrack_app WITH LOGIN IN ROLE app_runtime_grp;
        -- Set runtime password securely outside public scripts
    END IF;
END $$;
```

---

## 12. Database Privileges and Memberships Restoration Procedure

Once the roles are instantiated on the cluster, schema and object privileges must be restored according to the BoardTrack access model:

### 12.1 Database and Schema Level Grants
```sql
-- Connect to the target database
\c boardtrack_db

-- Enforce ownership
ALTER DATABASE boardtrack_db OWNER TO boardtrack_owner;
GRANT ALL ON SCHEMA public TO boardtrack_owner;

-- Schema USAGE permissions
GRANT USAGE ON SCHEMA public TO boardtrack_admin_grp;
GRANT USAGE ON SCHEMA public TO app_runtime_grp;
GRANT USAGE ON SCHEMA public TO app_readonly_grp;
```

### 12.2 Table and View Grants
```sql
-- 1. boardtrack_admin_grp: Full DML on all public tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO boardtrack_admin_grp;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO boardtrack_admin_grp;

-- 2. app_runtime_grp: Operational permissions required by Node.js web server
GRANT SELECT, INSERT, UPDATE, DELETE ON 
    property, room, tenant, lease, payment, utility_bill, app_user 
    TO app_runtime_grp;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_runtime_grp;
GRANT SELECT ON v_lease_summary TO app_runtime_grp;

-- 3. app_readonly_grp: Read-only reporting access
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly_grp;
GRANT SELECT ON v_lease_summary TO app_readonly_grp;
```

### 12.3 Default Privileges for Future Objects
To ensure future migrations inherit correct permissions:
```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_runtime_grp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO app_runtime_grp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO app_readonly_grp;
```

---

## 13. Summary Checklist for Emergency Recovery

1. [ ] Check PostgreSQL service availability on target host (`pg_isready`).
2. [ ] Recreate cluster roles using `globals_backup.sql` or `roles-and-privileges.sql`.
3. [ ] Create a clean, isolated restoration target database (`createdb -U postgres ...`).
4. [ ] Verify archive cryptographic hash against recorded SHA-256 baseline.
5. [ ] Execute `pg_restore` using custom archive format (`pg_restore -d <target_db> <dumpfile>`).
6. [ ] Execute automated verification suite (`verification.sql`) to validate table counts, constraints, triggers, and sequences.
7. [ ] Validate database and web application connectivity (`npm start`).
8. [ ] Document incident timeline, root cause, and recovery outcomes.

