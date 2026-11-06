# PostgreSQL Backup & Disaster Recovery Plan

**Project:** BWIS IT Solutions – Campus Canteen Pre-Order & Queue Management System  
**Course:** COMP 018 – Database Administration (Activity 6)  
**Database Platform:** PostgreSQL 18.6 (x86_64-windows)  
**Target Database:** `canteendb`  

---

## 1. Database and Objects to Back Up

The backup scope encompasses the entire `canteendb` database and all objects under the `public` schema:

- **Tables (7 Application Entities):**
  1. `student`: Student and administrator accounts, hashed credentials, and system roles.
  2. `vendor`: Food stall profiles, contact details, activation flags, and vendor authentication credentials.
  3. `menu_item`: Food and beverage offerings, current pricing, availability status, and stall foreign keys.
  4. `customer_order`: Pre-orders, scheduled pickup timestamps, fulfillment progress, and student/vendor linkages.
  5. `order_item`: Line-item details per pre-order, item references, ordered quantities, and unit price lock-in.
  6. `queue_entry`: Daily unique queue numbers, order references, queue date, and calling status.
  7. `notification`: Automated student notifications regarding order status changes.
- **Sequences (7 Primary Key Auto-Increment Generators):**
  - `student_student_id_seq`
  - `vendor_vendor_id_seq`
  - `menu_item_item_id_seq`
  - `customer_order_order_id_seq`
  - `order_item_order_item_id_seq`
  - `queue_entry_queue_id_seq`
  - `notification_notification_id_seq`
- **Schema Metadata & Constraints:**
  - 7 Primary Key constraints
  - 7 Foreign Key constraints with referential integrity rules
  - 4 Unique constraints (including compound `(queue_number, queue_date)`)
  - 7 Check constraints (price non-negativity, quantity positivity, order status enumeration, queue status enumeration, role validity)
  - 11 B-tree indexes
  - Object-level Access Control Lists (ACLs) for `canteen_app_grp` and `canteen_readonly_grp`.

---

## 2. Selected Logical Backup Method

The approved logical backup mechanism is **`pg_dump`** utilizing the **PostgreSQL Custom Archive Format (`-Fc`)**.

### Command Template
```powershell
pg_dump -U postgres -h 127.0.0.1 -p 5432 -Fc -d canteendb -f "C:\secure_backups\bwis_activity6.dump"
```

---

## 3. Technical Justification for Custom Archive Format (`-Fc`)

Choosing `pg_dump -Fc` over plain SQL text dumps (`-Fp`) or tar archives (`-Ft`) provides critical enterprise database advantages:

1. **Integrated High-Ratio Compression:** Built-in zlib compression significantly reduces file size (typically 75% to 85% compression ratio), reducing network transfer times and secondary storage consumption.
2. **Selective Object Restoration:** Unlike plain SQL scripts which must execute sequentially from start to finish, the custom format generates an indexed Table of Contents (TOC). Using `pg_restore`, administrators can inspect the TOC (`--list`) and restore individual tables, schemas, or specific constraints without restoring the entire database.
3. **Restoration Order Flexibility & Error Isolation:** `pg_restore` dynamically determines optimal dependency order during restoration (e.g., creating tables before adding foreign key constraints or restoring indexes after data loading to maximize ingestion throughput).
4. **Archive Integrity Verification:** The TOC structure enables immediate integrity validation via `pg_restore --list <archive>` prior to executing any destructive or test restoration.
5. **Cross-Platform Binary Portability:** Custom dump archives are portable across operating systems (e.g., backed up on Windows and restorable on Linux PostgreSQL instances).

---

## 4. Protected Backup Storage

Database backups contain sensitive operational data, including BCrypt password hashes and student personal identifiers. Storage protections must enforce:

- **Location Outside Git Repository:** Backups must **never** be stored within the source code tree or committed to version control. Backups are stored in an external protected filesystem directory (e.g., `C:\Users\Matt\.gemini\antigravity\brain\...\scratch\` or dedicated secure volume `D:\DatabaseBackups\bwis\`).
- **Filesystem Permissions (Least Privilege Access Control):**
  - Read/Write access restricted strictly to the Database Administrator account and the PostgreSQL service account (`NT AUTHORITY\NetworkService`).
  - Read/Write denied to application developers, student accounts, and unprivileged system users.
- **Git Protection:** The repository `.gitignore` explicitly excludes all dump patterns:
  ```gitignore
  *.dump
  *.backup
  *.dump.gz
  *.sql.gz
  backup/
  backups/
  ```
- **Off-Site Replication:** For production deployments, daily archives should be synced to an immutable, encrypted cloud object store (e.g., AWS S3 with Object Lock or Google Cloud Storage with bucket retention policies).

---

## 5. Authorized Backup Accounts

In compliance with the Activity 4 least-privilege security model:
- **Application Runtime Account (`canteen_app`):** **Prohibited** from running backups. `canteen_app` does not possess database superuser rights or catalog read access across system tables required for reliable full dumps.
- **Dedicated Maintenance Account (`canteen_admin` / `postgres`):**
  - Database owner `canteen_admin` or local superuser `postgres` executes scheduled backup jobs.
  - Credentials must **never** be hard-coded in scripts. Authentication is handled via local `pgpass.conf` (`127.0.0.1:5432:*:postgres:***`) or protected process environment variables (`$env:PGPASSWORD`) that are cleared immediately after execution.

---

## 6. Backup Verification Procedures

A backup is considered unverified and unsafe until proven restorable through a three-stage validation pipeline:

1. **Integrity Check (TOC Inspection):**
   ```powershell
   pg_restore --list bwis_activity6.dump
   ```
   Validates that the archive header is intact, zlib decompression succeeds, and the internal TOC table contains all 80 expected database entries.
2. **Cryptographic Checksumming:**
   ```powershell
   Get-FileHash -Path bwis_activity6.dump -Algorithm SHA256
   ```
   Generates a persistent SHA-256 fingerprint recorded in the backup log to detect storage corruption or unauthorized tampering.
3. **Automated Sandbox Restoration:**
   Weekly automated drills restore the latest archive into an isolated test database (`_restore_test`) and execute automated verification queries confirming:
   - All 7 tables and 7 sequences exist.
   - Primary, foreign key, unique, and check constraints are active.
   - Row counts match the source snapshot.
   - Representative multi-table joins execute without error.

---

## 7. Proposed Backup Schedule

To support the daily operations of the campus canteen (busiest hours: 07:00 – 19:00):

| Backup Type | Execution Time | Frequency | Purpose |
|---|---|---|---|
| **Full Logical Backup (`pg_dump -Fc`)** | 01:00 AM (Off-peak) | Daily | Complete snapshot of schema, sequences, data, and table ACLs. |
| **Differential / Snapshot Dump** | 13:30 PM (Post-lunch lull) | Daily | Mid-day safeguard capturing morning pre-orders and queue transactions. |
| **WAL Archiving (Continuous Archiving)** | Continuous (every 15 min or 16MB WAL segment) | Ongoing | Enables Point-In-Time Recovery (PITR) up to the minute of failure. |

---

## 8. Retention Policy (Grandfather-Father-Son)

| Retention Tier | Frequency | Retention Duration | Target Destination |
|---|---|---|---|
| **Daily Backups (Son)** | Daily full dumps | Retained for 7 days | Local high-speed NVMe storage |
| **Weekly Backups (Father)** | Sunday full dump | Retained for 4 weeks | Local secondary storage + Cloud mirror |
| **Monthly Backups (Grandfather)** | 1st of every month | Retained for 12 months | Immutable encrypted cold cloud archive |
| **Yearly Backups (Archive)** | End of academic term | Retained for 5 years | Regulatory / academic audit compliance |

---

## 9. Recovery Point Objective (RPO)

- **Target RPO:** **1 Hour** during operating canteen hours (07:00 – 19:00); **24 Hours** during off-peak night hours.
- **Acceptable Data Loss Analysis:** In a logical dump-only strategy without continuous WAL archiving, any orders placed between the 01:00 AM full backup and the time of disaster are lost. For high-volume canteen pre-orders, daily dumps alone would incur up to a 24-hour data loss window. Adding mid-day snapshot backups or continuous WAL streaming shrinks the RPO to under 15 minutes.

---

## 10. Recovery Time Objective (RTO)

- **Target RTO:** **30 Minutes** total elapsed time from disaster declaration to restored service.
- **RTO Breakdown:**
  1. Incident Detection & Server Provisioning: 10 minutes.
  2. Test Database Creation & `pg_restore` Execution: 5 minutes.
  3. Schema, Row Count & ACL Reapplication Verification: 5 minutes.
  4. Backend Connection String Reconfiguration & Service Restart: 10 minutes.

---

## 11. PostgreSQL Role Recreation Procedures

**Critical PostgreSQL Architectural Requirement:**
PostgreSQL roles (`pg_roles` / `pg_authid`) are **cluster-wide global objects**, not database-scoped objects. A single-database logical backup (`pg_dump -d canteendb`) does **not** contain role creation statements.

When restoring to a fresh or replacement PostgreSQL instance, DBAs must execute the following scripts in order **prior** to running `pg_restore`:
1. `db-access-control/01-create-roles.sql`:
   Creates roles `canteen_admin`, `canteen_app_grp`, `canteen_readonly_grp`, `canteen_app`, and `canteen_readonly`.
2. `db-access-control/02-role-memberships.sql`:
   Assigns `canteen_app` into `canteen_app_grp` and `canteen_readonly` into `canteen_readonly_grp`.

---

## 12. Privilege and Membership Restoration

1. **Object ACLs:** Automatically restored by `pg_restore` from the archive TOC entries.
2. **Database-Level Connect Privileges:** Because `createdb` initializes databases with default public permissions (`datacl IS NULL`), the DBA must execute `db-access-control/03-database-privileges.sql` immediately after restore:
   ```sql
   REVOKE ALL ON DATABASE canteendb_restored FROM PUBLIC;
   GRANT CONNECT ON DATABASE canteendb_restored TO canteen_admin, canteen_app, canteen_readonly;
   ```
3. **Execution of Verification Suite:** Run `activity-6-bwis/verification.sql` to validate that permitted operations succeed and denied operations are blocked.

