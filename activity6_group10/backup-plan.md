# Database Backup Plan
## Project: BoardTrack – Property and Rental Management System
**Course:** COMP 018 – Database Administration  
**Activity:** Activity 6 – Database Backup, Restoration, and Recovery  
**Target Database:** `boardtrack_db`  
**Platform:** PostgreSQL 18 (x86_64 Windows / Linux compatible)  

---

### 1. Overview and Purpose

This document establishes the official database backup and disaster recovery policy for **BoardTrack**, a Node.js and PostgreSQL property management system. The plan ensures business continuity, compliance with institutional database administration standards, and rapid recovery from operational accidents, application faults, infrastructure outages, or data corruption.

---

### 2. Scope of Backup Operations

The backup procedures cover all database objects, relational schemas, constraints, business logic routines, and persistent state within the `boardtrack_db` database:

1. **Relational Base Tables:**
   - `property` (property inventory)
   - `room` (rentable unit details)
   - `tenant` (renter identity records)
   - `lease` (lease agreements and contractual terms)
   - `payment` (financial transactions and ledger)
   - `utility_bill` (utility assessments)
   - `app_user` (application credentials and role assignments)
   - `schema_migrations` (migration state tracking)
2. **Sequences:** Auto-incrementing identity generators for all 7 base tables (`property_property_id_seq`, `room_room_id_seq`, `tenant_tenant_id_seq`, `lease_lease_id_seq`, `payment_payment_id_seq`, `utility_bill_utility_bill_id_seq`, `app_user_user_id_seq`).
3. **Database Views:** `v_lease_summary` (computed financial and billing aggregates).
4. **Procedural Logic & Triggers:**
   - Functions: `sync_room_status()`, `guard_room_status()`.
   - Triggers: `trg_lease_sync_room` on `lease`, `trg_room_status_guard` on `room`.
5. **Extensions & Custom Index Types:**
   - `btree_gist` (enabling multi-column GiST exclusion constraints).
   - `pgcrypto` (enabling bcrypt hash verification via `crypt()`).
6. **Integrity Constraints:**
   - Primary Keys, Foreign Keys (`ON DELETE NO ACTION`).
   - Check Constraints (domain and business rules).
   - Exclusion Constraint: `ex_lease_no_overlap` (blocking concurrent active leases).

---

### 3. Logical Backup Methodology & Justification for Custom Format (`-Fc`)

#### 3.1 Selected Backup Utility
Backup operations utilize PostgreSQL’s native logical backup tool: `pg_dump`.

#### 3.2 Command Specification
```powershell
pg_dump -U <BACKUP_USER> -h localhost -p 5432 -Fc -d boardtrack_db -f <BACKUP_DESTINATION>\boardtrack_activity6.dump
```

#### 3.3 Technical Justification for Custom Archive Format (`-Fc`)
While plain SQL format (`-Fp`) generates plain text SQL scripts, the **PostgreSQL Custom Archive Format (`-Fc`)** is selected for the following technical reasons:

1. **Built-in Compression:** The `-Fc` format applies zlib compression by default, significantly reducing disk storage footprint and accelerating network transfer speeds (reducing dump size by 70–85% compared to raw SQL).
2. **Flexible & Selective Object Restoration:** Unlike plain SQL scripts which must be executed sequentially, custom archives maintain an internal Table of Contents (TOC). The DBA can use `pg_restore` to restore single tables, specific schemas, views, or data only without touching other objects.
3. **Restoration Order Customization:** The TOC can be inspected, reordered, or edited using `pg_restore --list` and `pg_restore --use-list`, allowing DBAs to bypass problematic constraints or alter dependency resolution during complex recovery operations.
4. **Parallel Restoration (`-j` / `--jobs`):** Custom format dumps support multi-threaded parallel restoration when restoring into PostgreSQL, cutting recovery times dramatically for larger datasets.
5. **Security and Injection Resistance:** Plain text SQL scripts are vulnerable to accidental text corruption or malicious tampering. Custom archive binaries cannot be easily modified in a text editor and are parsed strictly by PostgreSQL archive handlers.
6. **Binary Large Object (BLOB) Support:** Custom format natively preserves large objects and complex schema extensions cleanly across differing collation environments.

---

### 4. Storage Architecture and Security

#### 4.1 Storage Location
All backup archives must be stored **strictly outside the Git repository tree** and outside web-accessible document roots.
- **Primary Dedicated Directory:** `C:\PostgreSQL\Backups\boardtrack\` (Windows) or `/var/backups/postgres/boardtrack/` (Linux).
- **Secondary Off-Host Replica:** Encrypted off-site storage or secondary storage tier.
- **Git Repository Exclusion:** The repository `.gitignore` explicitly blocks `*.dump`, `*.tar`, `*.sql.gz`, and any files in `backup/` directories.

#### 4.2 Access Control and File System Permissions
- **Windows NTFS Permissions:** Restricted via Windows ACLs to the `SYSTEM` account, the PostgreSQL service account (`NT SERVICE\postgresql-x64-18`), and the authorized Database Administrator group. Inheritance is disabled; `Everyone`, `Users`, and web server runtime accounts are granted zero access.
- **Zero Plaintext Secrets:** Backup automation scripts must never hardcode database credentials. Authentication is handled via `%APPDATA%\postgresql\pgpass.conf` or environment-injected secrets with strict file permissions (`0600`).

---

### 5. Authorized Backup Accounts & Least-Privilege Model

In accordance with least-privilege principles, scheduled backup tasks should not run under the `postgres` superuser account.
- **Dedicated Backup Role:** `boardtrack_backup`
  - Attributes: `LOGIN`, `NOSUPERUSER`, `NOCREATEDB`, `NOCREATEROLE`, `NOINHERIT`.
  - Cluster Permissions: Granted the predefined PostgreSQL role `pg_read_all_data`, or granted `CONNECT` on `boardtrack_db`, `USAGE` on schema `public`, and `SELECT` on all tables and sequences.
  - Connection Limits: Enforced to max 2 concurrent sessions (`CONNECTION LIMIT 2`).

---

### 6. Cluster-Wide Roles and Memberships Recovery

#### 6.1 Critical Architectural Limitation of `pg_dump`
A standard `pg_dump` archive captures only objects residing within a **single database**. In PostgreSQL, users and roles (`pg_roles`, `pg_authid`) and role memberships (`pg_auth_members`) are **cluster-wide (global) catalog objects**. 
> **Important:** Running `pg_restore` on a fresh cluster will fail to restore object ownership and privileges if the referenced roles do not exist prior to restoration.

#### 6.2 Role Recreation & Globals Backup Procedure
To ensure complete disaster recovery, global objects must be dumped separately:
1. **Automated Globals Backup:**
   ```powershell
   pg_dumpall -U postgres -h localhost -p 5432 --globals-only -f <BACKUP_DESTINATION>\boardtrack_globals.sql
   ```
2. **Declarative Role Recreation DDL:**
   If restoring to an environment where `pg_dumpall` is unavailable, execute the declarative role setup script before executing `pg_restore`:
   ```sql
   -- 1. Create group roles (NOLOGIN)
   CREATE ROLE boardtrack_admin_grp WITH NOLOGIN;
   CREATE ROLE app_runtime_grp WITH NOLOGIN;
   CREATE ROLE app_readonly_grp WITH NOLOGIN;

   -- 2. Create login accounts
   CREATE ROLE boardtrack_owner WITH LOGIN PASSWORD '<SECURE_PASSWORD>';
   CREATE ROLE boardtrack_app WITH LOGIN PASSWORD '<SECURE_PASSWORD>' IN ROLE app_runtime_grp;

   -- 3. Grant schema and sequence permissions
   GRANT CONNECT ON DATABASE boardtrack_db TO app_runtime_grp, app_readonly_grp, boardtrack_admin_grp;
   GRANT USAGE ON SCHEMA public TO app_runtime_grp, app_readonly_grp, boardtrack_admin_grp;
   GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_runtime_grp;
   ```

---

### 7. Backup Verification & Validation Framework

A backup cannot be considered valid until its integrity and restorability are empirically verified:

1. **File System Integrity Check:** Confirm file creation, non-zero file length, and expected size boundaries.
2. **Cryptographic Checksum:** Calculate and store SHA-256 hash immediately upon backup completion (`Get-FileHash -Algorithm SHA256`).
3. **Archive TOC Validation:** Run `pg_restore --list <dump_file>` to confirm header integrity, valid compression blocks, and uncorrupted object catalogs.
4. **Isolated Test Restoration:** Automatically restore into a dedicated, disposable validation database (`boardtrack_db_activity6_restore_test`).
5. **Structural and Relational Verification:** Execute automated verification queries (`verification.sql`) checking:
   - Base table count and row count consistency.
   - Referential integrity (no orphaned foreign key references).
   - Sequence continuity (`last_value >= MAX(id)`).
   - View execution (`SELECT * FROM v_lease_summary LIMIT 1`).

---

### 8. Backup Scheduling, Retention, and Metrics (RPO / RTO)

#### 8.1 Proposed Backup Schedule
| Frequency | Backup Type | Target Time | Destination | Retention |
|---|---|---|---|---|
| **Daily** | Full Logical (`pg_dump -Fc`) | 02:00 AM (off-peak) | Local Backup Storage (`C:\PostgreSQL\Backups\`) | 7 Days |
| **Weekly** | Full Logical + Globals (`pg_dumpall -g`) | Sunday 03:00 AM | Secondary Storage / External Volume | 4 Weeks |
| **Monthly** | Full Archive + Verification Report | 1st of Month 04:00 AM | Cold / Archive Storage | 12 Months |

#### 8.2 Recovery Objectives
- **Recovery Point Objective (RPO):** **24 Hours** using daily logical dumps. (Can be reduced to **< 15 minutes** if PostgreSQL Write-Ahead Log (WAL) archiving / Point-In-Time Recovery (PITR) is activated in `postgresql.conf`).
- **Recovery Time Objective (RTO):** **< 15 Minutes**. For the BoardTrack database size (< 100 MB), complete database creation, custom-format restoration via `pg_restore`, and integrity verification requires less than 3 minutes on standard hardware.

---

### 9. Disaster Recovery Incident Workflow

When responding to database failure or data loss:
1. **Assess Incident Scope:** Determine whether corruption is localized (single table/row) or cluster-wide.
2. **Preserve Current State:** Never overwrite the active database in place. Take a snapshot of surviving data and write-ahead logs.
3. **Provision Target Database:** Create a fresh target database with suffix `_restore_test` or `_recovery_target`.
4. **Verify Pre-requisite Roles:** Verify that all required roles exist in `pg_roles`.
5. **Execute `pg_restore`:** Restore the most recent verified backup archive.
6. **Verify Data and Relationships:** Run `verification.sql` to confirm row counts and constraint integrity.
7. **Switch Application Connection:** Update `DATABASE_URL` or redirect traffic to the verified recovered database.

