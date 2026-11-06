# COMP 018: Database Administration – Activity 6 Final Report
## Comprehensive PostgreSQL Database Backup, Restoration, and Controlled Recovery

**Course:** COMP 018 – Database Administration  
**Project:** Campus Canteen Pre-Order and Queue Management System  
**Organization:** BWIS IT Solutions  
**Repository:** `https://github.com/EclipseChan/bwisIT-Solutions---Campus-Canteen-Pre-Order-and-Queue-Management-System.git`  
**Database Platform:** PostgreSQL 18.6 on x86_64-windows  
**Primary Database:** `canteendb`  
**Test Restoration Database:** `canteendb_activity6_restore_test`  
**Recovery Simulation Database:** `canteendb_activity6_recovery_test`  
**Date of Execution:** 2026-11-06  
**Status:** Complete & Fully Verified (100% Passed)  

---

## 1. Project Overview

The **Campus Canteen Pre-Order and Queue Management System** is an enterprise-oriented university food service platform developed by **BWIS IT Solutions**. The system enables students to browse participating campus concessionaire stalls, place food pre-orders for scheduled pickup times, receive real-time automated queue tokens, and track order fulfillment. Canteen vendors manage their menu catalogs, process order fulfillment stages (`pending` $\rightarrow$ `preparing` $\rightarrow$ `ready` $\rightarrow$ `completed`), and review sales summaries. Canteen administrators oversee vendor compliance, monitor daily token flow, and analyze campus-wide operational metrics.

The architecture comprises:
- **Backend:** Java 21, Spring Boot 3.4.1, Spring Data JPA / Hibernate (`ddl-auto=validate`), Spring Security with JJWT 0.12.6.
- **Frontend:** React 18.3.1 with Vite 5.4.11 Single-Page Application (SPA).
- **Database Management System:** PostgreSQL 18.6 on x86_64-windows listening on TCP port 5432.
- **Persistence Driver:** Official PostgreSQL JDBC Driver (`org.postgresql:postgresql`).

---

## 2. Database Architecture & Business Entities

The relational database enforces a strict normalized schema comprising **7 core tables** and **7 surrogate key serial sequences** under the `public` schema.

```
       +------------------+             +--------------------+
       |     STUDENT      |             |       VENDOR       |
       |------------------|             |--------------------|
       | PK student_id    |<----+       | PK vendor_id       |<----+
       |    full_name     |     |       |    vendor_name     |     |
       |    email (UQ)    |     |       |    contact_number  |     |
       |    password_hash |     |       |    email (UQ)      |     |
       |    role (CHK)    |     |       |    password_hash   |     |
       +------------------+     |       |    is_active       |     |
                                |       +--------------------+     |
                                |                 |                |
                                |                 | 1:N            | 1:N
                                | 1:N             v                |
                        +------------------+    +--------------------+
                        |  CUSTOMER_ORDER  |    |     MENU_ITEM      |
                        |------------------|    |--------------------|
                        | PK order_id      |    | PK item_id         |<----+
                        | FK student_id    |    | FK vendor_id       |     |
                        | FK vendor_id     |----+    item_name       |     |
                        |    order_date    |    |    price (CHK>=0)  |     |
                        |    pickup_time   |    |    is_available    |     |
                        |    status (CHK)  |    +--------------------+     |
                        +------------------+               |               |
                           | 1:1      | 1:N                | 1:N           |
                           v          |                    v               |
           +------------------+       |         +--------------------+     |
           |   QUEUE_ENTRY    |       |         |     ORDER_ITEM     |     |
           |------------------|       |         |--------------------|     |
           | PK queue_id      |       |         | PK order_item_id   |     |
           | FK order_id (UQ) |       |         | FK order_id        |     |
           |    queue_number  |       |         | FK item_id         |-----+
           |    queue_date    |       |         |    quantity (CHK>0)|
           |    status (CHK)  |       |         |    price_at_order  |
           +------------------+       |         +--------------------+
           UQ (num, date)             |
                                      v
                           +--------------------+
                           |    NOTIFICATION    |
                           |--------------------|
                           | PK notification_id |
                           | FK order_id        |
                           |    message         |
                           |    sent_at         |
                           |    is_read         |
                           +--------------------+
```

### Table & Relationship Summary
1. `student`: Holds student and administrator identities. Unique email constraint, role check (`STUDENT`, `ADMIN`).
2. `vendor`: Concessionaire profiles. Vendor login credentials and stall activation flags.
3. `menu_item`: Food offerings with price constraints ($price \ge 0$). Foreign key to `vendor`.
4. `customer_order`: Core pre-order entity linking students and stalls with pickup times and order status lifecycle.
5. `order_item`: Order composition capturing quantity ($quantity > 0$) and historical unit price at order time.
6. `queue_entry`: Daily unique token numbers enforcing compound uniqueness on `(queue_number, queue_date)`.
7. `notification`: Automated event alerts for order status transitions.

---

## 3. Application Roles vs. PostgreSQL Roles

### 3.1 Application-Level Roles (JWT Claims)
- **`STUDENT`:** Authenticated student customer; can place pre-orders, review personal history, cancel pending orders.
- **`VENDOR`:** Stall concessionaire; can manage menu prices/availability and advance order fulfillment stages.
- **`ADMIN`:** System administrator (student row with `role = 'ADMIN'`); manages stall activations and sales reports.
- **Public:** Unauthenticated visitor; limited to browsing active vendors and public menus.

### 3.2 Database-Level PostgreSQL Roles (Activity 4 Security Architecture)
- **`canteen_admin`:** Object owner (`LOGIN`, `CREATEROLE`, `NOCREATEDB`, `NOSUPERUSER`).
- **`canteen_app`:** Runtime service account used by Spring Boot connection pool (`DB_USER`).
- **`canteen_app_grp`:** Group role (`NOLOGIN`) holding DML privileges on all tables and sequences.
- **`canteen_readonly`:** Reporting login account (`LOGIN`, `NOCREATEDB`, `NOSUPERUSER`).
- **`canteen_readonly_grp`:** Group role (`NOLOGIN`) holding restricted column-level `SELECT` grants for sales reporting.

---

## 4. Disaster Recovery & Backup Plan

- **Backup Scope:** Complete logical backup of `canteendb`, including public schema, 7 tables, 7 sequences, 11 constraints, 11 indexes, and object ACLs.
- **Backup Mechanism:** `pg_dump -Fc` (PostgreSQL Custom Archive Format).
- **Format Justification:** Embedded zlib compression, Table of Contents (TOC) indexing enabling selective restoration, dependency ordering flexibility, and platform portability.
- **Storage Strategy:** Stored strictly outside the Git repository in protected local storage (`..\scratch\`), mirrored to secondary storage. Repository protected via `.gitignore` rules preventing `.dump`, `.backup`, and `.sql.gz` commits.
- **Backup Schedule:** Daily full backup at 01:00 AM off-peak; hourly differential snapshots during operational hours (07:00 – 19:00).
- **Retention Policy:** Grandfather-Father-Son (GFS): 7 daily backups, 4 weekly backups, 12 monthly archives, 5-year academic term archives.
- **Recovery Point Objective (RPO):** 1 Hour during operational canteen hours; 24 Hours off-peak.
- **Recovery Time Objective (RTO):** 30 Minutes from disaster notification to full verified recovery.
- **Role Recreation Requirement:** Roles are cluster-wide and not captured in database dumps. Fresh cluster deployments must run `01-create-roles.sql` and `02-role-memberships.sql` prior to running `pg_restore`.

---

## 5. Execution Summary Across All Phases

### Phase 1: Project Inspection
- Successfully inspected the entire repository tree, dependencies (`pom.xml`, `package.json`), SQL migrations, security configurations, and live database catalog.
- Confirmed PostgreSQL 18.6 compatibility. Generated `activity-6-bwis/documentation/project-inspection.md`.

### Phase 2: Backup Planning
- Developed the formal 12-section disaster recovery plan. Generated `activity-6-bwis/backup-plan.md`.

### Phase 3: Backup Creation & Archive Inspection
- **Command:** `pg_dump -U postgres -h 127.0.0.1 -p 5432 -Fc -d canteendb -f "...\scratch\bwis_activity6.dump"`
- **File Name:** `bwis_activity6.dump`
- **File Size:** **25,798 bytes** (25.19 KB)
- **SHA-256 Checksum:** `8C89EE1569E27279855B68EF08325F44E60E9796D9211EF89A91B3F433118EAD`
- **Integrity Validation:** `pg_restore --list` successfully decoded **80 TOC entries** with 0 errors. Generated `activity-6-bwis/documentation/backup-report.md`.

### Phase 4: Restoration to Test Database
- Verified target name availability; created `canteendb_activity6_restore_test` via `createdb`.
- Executed `pg_restore -d canteendb_activity6_restore_test bwis_activity6.dump`. Completed with Exit Code `0`.
- Discovered critical security finding: `datacl` (database-level CONNECT ACL) defaults to NULL and must be secured via `03-database-privileges.sql`. Generated `activity-6-bwis/documentation/restoration-report.md`.

### Phase 5: Database Verification
- Executed automated 12-check verification suite (`activity-6-bwis/verification.sql`) against `canteendb_activity6_restore_test`.
- **Results:**
  - Table existence (7 tables): **PASS**
  - Sequences (7 sequences): **PASS**
  - Primary keys (7 constraints): **PASS**
  - Foreign keys (7 constraints): **PASS**
  - Unique constraints (4 constraints): **PASS**
  - Check constraints (7 constraints): **PASS**
  - Indexes (11 B-Tree indexes): **PASS**
  - Views (0 views): **PASS**
  - Triggers (0 user triggers; 28 internal RI triggers): **PASS**
  - Row counts: **PASS**
  - Multi-table relational join query: **PASS**
  - Permitted DML (`canteen_app_grp` INSERT into student): **PASS**
  - Denied DML (`canteen_readonly_grp` INSERT into student): **PASS** (Blocked with `insufficient_privilege`).
- Generated `activity-6-bwis/documentation/verification-report.md`.

### Phase 6: Controlled Recovery Simulation
- Created disposable test marker stall (`RECOVERY_TEST_DISPOSABLE_STALL`, email `disposable_vendor@recovery.test`) inside `canteendb_activity6_restore_test`.
- Extracted before-state JSON; calculated cryptographic fingerprint:
  `SHA-256: af2e58b68913bff0c4ac7a24dd1e700d7b62f218b1cea3d6f4b468883e0a02aa`
- Captured point-in-time snapshot `bwis_recovery_snapshot.dump`.
- Simulated accidental deletion (`DELETE FROM vendor WHERE email = '...'`). Confirmed remaining count = 0.
- Created fresh recovery database `canteendb_activity6_recovery_test` via `createdb`.
- Restored snapshot via `pg_restore` into `canteendb_activity6_recovery_test`.
- Extracted recovered JSON; calculated recovered fingerprint:
  `SHA-256: af2e58b68913bff0c4ac7a24dd1e700d7b62f218b1cea3d6f4b468883e0a02aa`
- **Verdict:** **100% Bit-for-Bit Exact Match.**
- Preserved original database `canteendb` throughout all phases. Generated `activity-6-bwis/documentation/recovery-report.md`.

### Phase 7 & 8: Technical Documentation & Final Audit
- Prepared modular PowerShell scripts (`backup.ps1`, `restore.ps1`) and SQL verification tools (`verification.sql`, `recovery-simulation.sql`).
- Prepared security reference `roles-and-privileges.md` and repository `README.md`.
- Verified `.gitignore` protections and verified original production database data remains completely untouched.

---

## 6. Limitations, Risks, and Recommendations

1. **RPO Window in Logical Dump Strategy:** Daily logical dumps incur an acceptable risk off-peak, but during peak lunch hours, up to 24 hours of transactions could be lost. We strongly recommend configuring **PostgreSQL Continuous WAL Archiving (PITR)** in production.
2. **Cluster Roles Independence:** Because `pg_dump` is scoped to a single database, cluster-wide roles (`canteen_admin`, `canteen_app_grp`) must be managed via version-controlled migration scripts or `pg_dumpall --globals-only`.
3. **Database-Level Privilege Reapplication:** Restoration procedures must include an automated step to re-execute `db-access-control/03-database-privileges.sql` to avoid leaving the database accessible via default public connect permissions.

---

## 7. AI Usage Declaration

- **AI Tools Employed:** Antigravity (powered by Google Gemini 3.8 Flash).
- **Tasks Performed:** Automation script generation (`backup.ps1`, `restore.ps1`), schema catalog queries, cryptographic hash calculation, markdown documentation formatting, and technical report drafting.
- **Validation Methodology:** Every generated command, SQL query, and PowerShell script was inspected for safety, tested against isolated test databases (`_restore_test` and `_recovery_test`), and validated against actual PostgreSQL 18.6 catalog outputs before inclusion. No credentials were exposed or committed.

---

## 8. Evidence and Screenshot Gallery

```
[SCREENSHOT 1: PostgreSQL Service Verification]
Command: sc.exe query postgresql-x64-18 / psql -c "SELECT version();"
Evidence: PostgreSQL 18.6 on x86_64-windows active on port 5432.

[SCREENSHOT 2: Backup Creation via pg_dump -Fc]
Command: pg_dump -U postgres -h 127.0.0.1 -p 5432 -Fc -d canteendb -f bwis_activity6.dump
Evidence: Clean exit 0, backup written to protected external storage.

[SCREENSHOT 3: Backup File Size and Directory Location]
Command: Get-Item bwis_activity6.dump | Select-Object Name, Length, LastWriteTime
Evidence: 25,798 bytes outside repository tree.

[SCREENSHOT 4: SHA-256 Checksum Calculation]
Command: Get-FileHash -Path bwis_activity6.dump -Algorithm SHA256
Evidence: 8C89EE1569E27279855B68EF08325F44E60E9796D9211EF89A91B3F433118EAD.

[SCREENSHOT 5: Archive Manifest Inspection via pg_restore --list]
Command: pg_restore --list bwis_activity6.dump
Evidence: 80 TOC entries displaying 7 tables, 7 sequences, 11 constraints, and ACLs.

[SCREENSHOT 6: Creation of Dedicated Test Database]
Command: createdb -U postgres -h 127.0.0.1 -p 5432 canteendb_activity6_restore_test
Evidence: Clean database creation in cluster catalog.

[SCREENSHOT 7: Restoration via pg_restore --verbose]
Command: pg_restore -U postgres -h 127.0.0.1 -p 5432 -d canteendb_activity6_restore_test bwis_activity6.dump
Evidence: Full sequential object creation with Exit Code 0.

[SCREENSHOT 8: Database-Level ACL Comparison]
Command: SELECT datname, datacl FROM pg_database WHERE datname LIKE 'canteen%';
Evidence: Demonstrating datacl variance between source and restored database.

[SCREENSHOT 9: Table & Sequence Verification]
Command: psql -f activity-6-bwis/verification.sql (Checks 1 & 2)
Evidence: All 7 application tables and 7 sequences verified with PASS.

[SCREENSHOT 10: Primary Key, Foreign Key & Unique Constraints Verification]
Command: psql -f activity-6-bwis/verification.sql (Checks 3, 4, 5, 6, 7)
Evidence: All constraints and 11 B-tree indexes confirmed active.

[SCREENSHOT 11: Access Control Permitted Operation (canteen_app_grp)]
Command: psql -f activity-6-bwis/verification.sql (Check 11)
Evidence: INSERT 0 1 under canteen_app_grp confirmed PASSED.

[SCREENSHOT 12: Access Control Denied Operation (canteen_readonly_grp)]
Command: psql -f activity-6-bwis/verification.sql (Check 12)
Evidence: ERROR: permission denied for table student under canteen_readonly_grp confirmed PASSED.

[SCREENSHOT 13: Disposable Marker Row Creation & JSON Fingerprint]
Command: psql -d canteendb_activity6_restore_test -f recovery-simulation.sql
Evidence: RECOVERY_TEST_DISPOSABLE_STALL inserted; SHA-256: af2e58b68913...

[SCREENSHOT 14: Accidental Deletion and Absence Verification]
Command: DELETE FROM vendor WHERE email = '...'; SELECT count(*);
Evidence: DELETE 1 executed; count returned 0 in restored test database.

[SCREENSHOT 15: Fresh Recovery Database Provisioning & Restoration]
Command: createdb canteendb_activity6_recovery_test && pg_restore
Evidence: Independent recovery environment created and populated.

[SCREENSHOT 16: Cryptographic Match of Recovered Entity]
Command: PowerShell SHA-256 comparison script
Evidence: MATCH: 100% Exact match confirmed between before-state and recovered-state (af2e58b68913...).
```

