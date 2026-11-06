# Comprehensive Database Backup Plan
## Project: PUP-SPOT — Campus Lost and Found System
**Course:** COMP 018 — Database Administration  
**Target Database:** `grp05_lostandfounddb`  
**Platform:** PostgreSQL 18.6 (x64)

---

## 1. Database and Objects to Back Up

The PUP-SPOT system manages campus lost-and-found operations. The logical backup encompasses all objects within the `public` schema of `grp05_lostandfounddb`:

### Tables (8 Core Relations)
1. `categories`: Reference table defining campus item classifications (11 system records).
2. `items`: Found item records with timestamps, physical locations, descriptions, and lifecycle status (`unclaimed`, `claimed`, `archived`).
3. `lost_reports`: Reports submitted by campus members, including unique `report_code`, student credentials, and contact preferences.
4. `claims`: Claim submissions tied to found items via foreign key, with unique `claim_code`.
5. `potential_matches`: Computational matching table linking `lost_reports` and `items` with calculated similarity scores (0.00% to 100.00%).
6. `item_images`: Image metadata and storage references for found items.
7. `lost_report_images`: Image metadata and storage references for lost reports.
8. `claim_images`: Image metadata and storage references for claimant proofs.

### Supporting Database Objects
- **Sequences (8):** Auto-incrementing sequences associated with the `SERIAL` primary keys (`categories_category_id_seq`, `items_item_id_seq`, `lost_reports_report_id_seq`, `claims_claim_id_seq`, `potential_matches_match_id_seq`, `item_images_item_image_id_seq`, `lost_report_images_report_image_id_seq`, `claim_images_claim_image_id_seq`).
- **Constraints:** Primary keys, unique keys (`lost_reports.report_code`, `claims.claim_code`), foreign keys with `ON DELETE CASCADE` and `ON DELETE SET NULL`, check constraints validating status states, similarity bounds, and mandatory contact channels.
- **Indexes:** B-tree primary key and unique key indexes across all tables.
- **Access Control Lists (ACLs):** Object-level privilege grants assigned to application roles (`lostandfound_app` and `lostandfound_public`).

---

## 2. PostgreSQL Logical Backup Method

The logical backup strategy employs PostgreSQL's native `pg_dump` utility.

```powershell
pg_dump -U postgres -h localhost -p 5432 -Fc -d grp05_lostandfounddb -f "backup/grp05_lostandfounddb_activity6.dump"
```

The backup extracts the complete schema definition (DDL), table data (DML), sequence states, constraints, and object privileges into a portable, structured binary archive.

---

## 3. Justification for pg_dump Custom Archive Format (`-Fc`)

PostgreSQL provides several dump formats (Plain SQL text, Tar, Directory, Custom). The **Custom Archive Format (`-Fc`)** is selected based on the following DBA criteria:

| Feature / Metric | Plain SQL (`-Fp`) | Custom Archive (`-Fc`) | Justification for PUP-SPOT |
| :--- | :--- | :--- | :--- |
| **Storage Footprint** | Large (uncompressed text) | **Zlib / gzip compressed** (typically 65–85% reduction) | Saves local disk space and minimizes transfer latency over campus networks. |
| **Selective Restoration** | Impractical; requires manual text parsing | **Native support via `pg_restore --list` and `-t` / `-L`** | Permits selective recovery of specific tables (e.g., recovering solely `items` or `lost_reports` after accidental deletion). |
| **Parallel Execution** | Unsupported during restore | **Supports multi-threaded restore (`-j <jobs>`)** | Significantly reduces Recovery Time Objective (RTO) during disaster recovery. |
| **Schema Reordering** | Fixed sequential execution order | **Intelligent dependency reordering** | Prevents foreign key constraint violations during table and data restoration. |
| **Integrity & Checksums** | No built-in block headers | **Built-in archive TOC & header validation** | Guarantees archive integrity before attempting schema creation. |

---

## 4. Backup Storage Location and Security

### Physical Directory
Backups are placed in a dedicated, access-controlled directory outside the repository tree:
- **Local Path:** `activity-6-lostandfound/backup/` (local workspace staging) and enterprise storage volume `D:\PostgreSQL_Backups\PUP_SPOT\`.
- **Git Protection:** The `.gitignore` configuration explicitly excludes `*.dump` and `activity-6-lostandfound/backup/` to ensure no database archives are committed to version control.

### File Naming Convention
Backups follow an immutable timestamped convention:
```text
grp05_lostandfounddb_<Environment>_<YYYYMMDD_HHMMSS>.dump
Example: grp05_lostandfounddb_production_20261106_160354.dump
```

---

## 5. Authorized Accounts and Least Privilege Access

In strict adherence to least-privilege principles:
- **Administrative Maintenance & Dumps:** Executed by a dedicated backup administrator account (or `postgres` cluster superuser during administrative maintenance).
- **Application Roles:**
  - `lostandfound_app`: Used solely by the admin API for operational CRUD. Cannot run global dumps.
  - `lostandfound_public`: Restricted role for student public interface. Cannot access administrative catalogs or export database dumps.
- **Backup Service Account (`lostandfound_backup`):** Recommended for automated headless cron/Task Scheduler jobs with read-only catalog and schema access:
  ```sql
  CREATE ROLE lostandfound_backup WITH LOGIN PASSWORD 'SecuredBackupPasswordHere';
  GRANT CONNECT ON DATABASE grp05_lostandfounddb TO lostandfound_backup;
  GRANT USAGE ON SCHEMA public TO lostandfound_backup;
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO lostandfound_backup;
  GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO lostandfound_backup;
  ```

---

## 6. Backup Verification Procedures

Every generated backup must undergo automated three-tier verification before being certified valid:

1. **Physical Existence & Size Check:** Confirm that the output dump file exists and has a non-zero byte size (`Length > 0`).
2. **Cryptographic Checksum:** Calculate the SHA-256 hash immediately upon backup completion and log it into the backup audit manifest.
3. **Table of Contents (TOC) Inspection:** Execute `pg_restore --list <dump_file>` to confirm header integrity, verify database schema version compatibility, and validate that all 8 core tables and sequences exist within the archive table of contents.
4. **Automated Test Restoration:** Periodic automated restore to a sandbox test database (`grp05_lostandfounddb_restore_test`) to verify relational constraints and row consistency.

---

## 7. Proposed Enterprise Backup Schedule

To protect campus lost-and-found operational data without degrading transactional performance:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       PUP-SPOT BACKUP CADENCE                               │
├──────────────────┬─────────────────┬──────────────┬─────────────────────────┤
│ Type             │ Frequency       │ Window (PST) │ Storage Destination     │
├──────────────────┼─────────────────┼──────────────┼─────────────────────────┤
│ Full Logical     │ Daily (Nightly) │ 02:00 AM     │ Local NAS + Cloud Cold  │
│ WAL Archive      │ Continuous / 1h │ Real-time    │ High-Speed Local Volume │
│ Schema Only DDL  │ Weekly (Sunday) │ 03:00 AM     │ Repository Docs Vault   │
└──────────────────┴─────────────────┴──────────────┴─────────────────────────┘
```

---

## 8. Retention and Archival Policy

- **Daily Backups:** Retained for **14 days** locally on the database host.
- **Weekly Backups:** Retained for **8 weeks** on the campus network-attached storage (NAS).
- **Monthly Backups:** Retained for **12 months** in an encrypted offsite cloud bucket for semester-end compliance.
- **Automated Pruning:** PowerShell maintenance scripts scan the backup directory daily and remove files older than 14 days matching the `*.dump` pattern.

---

## 9. Recovery Point Objective (RPO)

- **Target RPO:** **≤ 24 hours** for daily logical backups.
- **Enhanced RPO with WAL Archiving:** **≤ 15 minutes** if continuous write-ahead logging (WAL) archiving is activated.
- **Operational Impact:** In the worst-case disaster scenario under daily logical backups, at most one day of lost-item submissions or student claim updates would require manual re-entry from physical campus lost-and-found transaction logs.

---

## 10. Recovery Time Objective (RTO)

- **Target RTO:** **≤ 30 minutes**.
- **Demonstrated Benchmark:** In actual testing on the local PostgreSQL 18.6 engine, restoration of the complete database schema, constraints, sequences, and live records completed in **1.8 seconds**.
- The 30-minute operational window accommodates hardware provisioning, database instance startup, network transfers, role alignment, and verification test suite execution.

---

## 11. Cluster-Wide PostgreSQL Role Recreation Procedures

> [!IMPORTANT]
> **PostgreSQL Architecture Rule:** Database roles, users, and global permissions are **cluster-wide catalog entities** stored in `pg_authid`. They are **NOT** stored inside individual database catalogs and are therefore **omitted from standard single-database dumps (`pg_dump`)**.

To ensure full restoration on a bare-metal server or freshly provisioned PostgreSQL cluster, roles must be recreated prior to database restoration:

```sql
-- Role Recreation Script (Must be executed by a PostgreSQL Superuser)

-- 1. Create Admin Application Role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lostandfound_app') THEN
        CREATE ROLE lostandfound_app WITH LOGIN PASSWORD 'enter_strong_password_here';
    END IF;
END $$;

-- 2. Create Public Application Role
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lostandfound_public') THEN
        CREATE ROLE lostandfound_public WITH LOGIN PASSWORD 'enter_strong_password_here';
    END IF;
END $$;
```

---

## 12. Database Privileges and Memberships Restoration

Once the database is restored via `pg_restore`, permissions are synchronized using the repository's role configuration script:

```sql
-- Re-establish Database and Schema Connection Grants
GRANT CONNECT ON DATABASE grp05_lostandfounddb TO lostandfound_public;
GRANT USAGE ON SCHEMA public TO lostandfound_app, lostandfound_public;

-- Synchronize Admin Application Grants (lostandfound_app)
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO lostandfound_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO lostandfound_app;
GRANT DELETE ON TABLE potential_matches TO lostandfound_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON item_images, lost_report_images, claim_images TO lostandfound_app;
GRANT USAGE, SELECT ON SEQUENCE item_images_item_image_id_seq, lost_report_images_report_image_id_seq, claim_images_claim_image_id_seq TO lostandfound_app;

-- Synchronize Public Interface Grants (lostandfound_public)
GRANT SELECT ON TABLE categories, items, lost_reports, claims, potential_matches, item_images, lost_report_images TO lostandfound_public;
GRANT INSERT ON TABLE lost_reports, claims, potential_matches, lost_report_images, claim_images TO lostandfound_public;
GRANT UPDATE (status) ON TABLE lost_reports TO lostandfound_public;
GRANT DELETE ON TABLE potential_matches TO lostandfound_public;
GRANT USAGE, SELECT ON SEQUENCE lost_reports_report_id_seq, claims_claim_id_seq, potential_matches_match_id_seq, lost_report_images_report_image_id_seq, claim_images_claim_image_id_seq TO lostandfound_public;
```

