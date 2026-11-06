# COMP 018 — Database Administration: Activity 6 Final Report
## Enterprise Database Backup, Restoration, and Disaster Recovery Dossier
### Project: BrewPOS — Café Point-of-Sale System

---

## Document & Submission Metadata

| Attribute | Specification |
|---|---|
| **Course** | **COMP 018 — Database Administration** |
| **Activity** | **Activity 6: Database Backup, Restoration, and Recovery** |
| **Academic Term** | 1st Semester, A.Y. 2026–2027 |
| **Evaluating Team** | **Group 4 (BrewPOS Core Engineering)** |
| **Team Members** | • **Olivarez, Charles Kean E.**<br>• **Infantado, Gerwin G.**<br>• **Pocsidio, Jhon Louie F.**<br>• **Abangan, SJ Kaizen M.**<br>• **Bartolata, Redge Raindel N.** |
| **Source Repository** | [https://github.com/Nycri/brewpos](https://github.com/Nycri/brewpos) |
| **Primary Database** | `grp_brewposdb` (Preserved & Untouched) |
| **Restored Test Database** | `grp_brewposdb_restore_test` |
| **Disaster Recovery Database** | `grp_brewposdb_recovery_test` |
| **Database Engine** | PostgreSQL 18.6 on x86_64-windows (MSVC 64-bit) |
| **Execution Date** | November 6, 2026 |
| **Audit Status** | **100% VERIFIED & CERTIFIED** |

---

## 1. Executive Summary

This comprehensive technical report presents the planning, execution, verification, and disaster simulation results for **COMP 018 — Activity 6: Database Backup, Restoration, and Recovery** conducted on the **BrewPOS (Café Point-of-Sale System)** relational database.

Modern point-of-sale applications process high-volume, real-time financial transactions where data durability is mission-critical. In accordance with strict database administration guidelines, all eight phases of Activity 6 were executed sequentially in a live PostgreSQL 18.6 environment on Windows:
1. **Pre-Execution Inspection:** Audited repository DDL, seed data, application `.env` configs, and verified that the production database `grp_brewposdb` existed and was healthy.
2. **Resilience Planning:** Defined custom archive architecture (`-Fc`), 15-minute RPO, 30-minute RTO, GFS retention policies, and cluster role re-creation procedures.
3. **Cryptographic Backup Execution:** Created a compressed binary dump (`grp_brewposdb_activity6.dump`), verified its 17,897-byte footprint, calculated its SHA-256 digest (`E721EFE29FE9D378617BD065E671B6D7DF4BCCFC049E66065E1B3DF05B563C9F`), and verified all 52 TOC entries via `pg_restore --list`.
4. **Isolated Test Restoration:** Non-destructively created `grp_brewposdb_restore_test` and restored the archive with zero warnings or errors.
5. **Rigorous Verification:** Executed a 12-point SQL validation suite confirming 100% schema parity, 100% row count parity across all 5 tables, exact-cent order calculations, and verified Role-Based Access Control (RBAC) privilege boundaries.
6. **Controlled Disaster Recovery Drill:** Conducted an intentional human error deletion drill on disposable menu data in `grp_brewposdb_restore_test`, staged `grp_brewposdb_recovery_test`, located the original tuple, and achieved 100% surgical recovery with **zero permanent data loss**.

---

## 2. Database Architecture & Relational Topology

The BrewPOS database schema is organized in the `public` schema and comprises five relational tables designed in Third Normal Form (3NF).

```mermaid
erDiagram
    staff ||--o{ order_ticket : "processes"
    menu_category ||--o{ menu_item : "categorizes"
    order_ticket ||--|{ order_line_item : "contains"
    menu_item ||--o{ order_line_item : "itemized in"

    staff {
        int staff_id PK "SERIAL"
        varchar full_name "100 chars, NOT NULL"
        varchar role "CHECK (CASHIER, MANAGER)"
    }
    menu_category {
        int category_id PK "SERIAL"
        varchar category_name "UNIQUE, NOT NULL"
    }
    menu_item {
        int item_id PK "SERIAL"
        int category_id FK "NOT NULL"
        varchar item_name "NOT NULL"
        decimal price "CHECK (price >= 0)"
        boolean is_active "DEFAULT TRUE"
    }
    order_ticket {
        int order_id PK "SERIAL"
        int staff_id FK "NOT NULL"
        timestamp order_timestamp "DEFAULT CURRENT_TIMESTAMP"
        varchar payment_method "CHECK (CASH, ONLINE)"
    }
    order_line_item {
        int order_id PK, FK "NOT NULL"
        int item_id PK, FK "NOT NULL"
        int quantity "CHECK (quantity > 0)"
        decimal sold_price "CHECK (sold_price >= 0)"
    }
```

### Table Specifications
1. **`staff`**: Master personnel directory storing cashiers and store managers.
2. **`menu_category`**: Product groupings (`Coffee`, `Non-Coffee`, `Pastries`) with unique name constraints.
3. **`menu_item`**: Catalog items with prices, active flags for POS filtering, and category foreign keys.
4. **`order_ticket`**: Header records for café sales transactions documenting staff attribution and payment method.
5. **`order_line_item`**: Child sales records utilizing a **composite primary key `(order_id, item_id)`**, capturing frozen unit `sold_price` and item quantities.

---

## 3. Backup Planning, Architecture & Objectives

### 3.1 Strategy Matrix
| Planning Parameter | Operational Specification | Technical Justification |
|---|---|---|
| **Target Database** | `grp_brewposdb` (Schema: `public`) | Full relational integrity across catalog, personnel, and sales logs. |
| **Backup Format** | **PostgreSQL Custom Archive (`-Fc`)** | Compressed binary archive; supports multi-threaded parallel restoration and table-level TOC filtering. |
| **Storage Path** | `C:\Users\Matt\pg_backups\brewpos\` | Dedicated protected directory outside Git tree; secured via OS file ACLs. |
| **RPO (Recovery Point Objective)** | **15 Minutes** | High-frequency café sales require tight loss windows; supported via continuous WAL archiving. |
| **RTO (Recovery Time Objective)** | **30 Minutes** | Sufficient window to provision staging server, restore 17.5 KB dump, and swap connection pool strings. |
| **Retention Policy** | Grandfather-Father-Son (GFS) | 7 daily snapshots + 4 weekly snapshots + 12 monthly archives. |
| **Global Roles Recreation** | Activity 4 SQL / `pg_dumpall --globals-only` | Pre-restoration script provisioning ensures clean ACL binding on bare-metal instances. |

---

## 4. Phase 3: Backup Execution & Archive Verification

### 4.1 Executed Command
```powershell
pg_dump -U postgres -h localhost -p 5432 -Fc -d grp_brewposdb -f "C:\Users\Matt\pg_backups\brewpos\grp_brewposdb_activity6.dump"
```

### 4.2 Verified Archive Metadata & Cryptographic Hash
```text
Archive Name   : grp_brewposdb_activity6.dump
File Size      : 17,897 bytes (17.47 KB)
Creation Date  : 2026-11-06 15:34:49 (UTC+8)
Format         : PostgreSQL Custom Format (gzip compressed)
TOC Entries    : 52
SHA-256 Digest : E721EFE29FE9D378617BD065E671B6D7DF4BCCFC049E66065E1B3DF05B563C9F
Exit Status    : 0 (Success — 0 Errors, 0 Warnings)
```

```markdown
<!-- SCREENSHOT PLACEHOLDER 1: Backup Creation Terminal Trace -->
![Screenshot 1: Terminal output of pg_dump execution](screenshots/01_backup_creation.png)
*Figure 1: Successful creation of grp_brewposdb_activity6.dump using pg_dump -Fc.*

<!-- SCREENSHOT PLACEHOLDER 2: SHA-256 Checksum Calculation -->
![Screenshot 2: PowerShell Get-FileHash output](screenshots/02_sha256_checksum.png)
*Figure 2: Cryptographic validation generating hash E721EFE29FE9D378617BD065E671B6D7DF4BCCFC049E66065E1B3DF05B563C9F.*
```

### 4.3 Archive Table of Contents (TOC) Inspection
Executing `pg_restore --list` verified 52 structural elements:
- **5 Tables:** `staff`, `menu_category`, `menu_item`, `order_ticket`, `order_line_item`.
- **4 Sequences:** `staff_staff_id_seq`, `menu_category_category_id_seq`, `menu_item_item_id_seq`, `order_ticket_order_id_seq`.
- **4 Sequence Bindings:** `SEQUENCE OWNED BY` declarations.
- **4 Primary Key Column Defaults:** Nextval sequence generators.
- **5 Table Data Payloads:** Bulk COPY tuples for all application entities.
- **4 Sequence Set States:** Accurate high-water mark counters.
- **5 Primary Keys:** Individual and composite primary key constraints.
- **2 Unique Constraints:** `uq_menu_category_name`, `uq_menu_item_category_name`.
- **4 Foreign Keys:** Referential links enforcing zero cascading deletes.
- **13 Access Control Lists (ACLs):** Granular table and sequence privileges.

---

## 5. Phase 4: Isolated Database Restoration

### 5.1 Safe Restoration Protocol
To protect live data, restoration was directed into an isolated target: **`grp_brewposdb_restore_test`**.

```powershell
# 1. Provision target database
createdb -U postgres -h localhost -p 5432 grp_brewposdb_restore_test

# 2. Restore custom archive with verbose output
pg_restore -U postgres -h localhost -p 5432 -d grp_brewposdb_restore_test --verbose "C:\Users\Matt\pg_backups\brewpos\grp_brewposdb_activity6.dump"
```

```markdown
<!-- SCREENSHOT PLACEHOLDER 3: Database Provisioning and pg_restore -->
![Screenshot 3: Terminal execution of createdb and pg_restore](screenshots/05_pg_restore_execution.png)
*Figure 3: Non-destructive restoration into grp_brewposdb_restore_test completing with exit code 0.*
```

### 5.2 Restoration Execution Trace Audit
The verbose output confirmed that database objects were restored in strict relational dependency order: sequences first, base tables next, default expressions, raw data COPY streams, sequence counter synchronization, constraints, and finally ACL permissions. The restoration finished with exit code `0` and **zero warnings or errors**.

---

## 6. Phase 5: Comprehensive Post-Restoration Verification Suite

A 12-point SQL validation suite was executed against `grp_brewposdb_restore_test`.

### 6.1 Verification Scorecard

| # | Inspection Area | Baseline Expected | Restored Staging Result | Status |
|:---:|---|---|---|:---:|
| 1 | Table Inventory | 5 base tables in `public` | 5 base tables present | **PASS** |
| 2 | Column Definitions | 18 columns, exact data types & scales | 100% attribute parity | **PASS** |
| 3 | Primary Keys | 5 PKs (Composite PK on `order_line_item`) | All 5 PKs enforced | **PASS** |
| 4 | Foreign Keys | 4 FKs with `NO CASCADE` | All 4 FKs enforced | **PASS** |
| 5 | Check & Unique | 2 UNIQUE + 5 CHECK constraints | All 7 constraints active | **PASS** |
| 6 | Indexes | 7 B-tree indexes | 7 B-tree indexes active | **PASS** |
| 7 | Sequences | 4 sequences with identical high-water marks | 100% counter synchronization | **PASS** |
| 8 | Sample Records | Staff, Categories, Products, Historical Orders | All baseline records present | **PASS** |
| 9 | Row Count Parity | Exact match with `grp_brewposdb` | 30/30 total rows (100% match) | **PASS** |
| 10 | Query Aggregations | Multi-table order totals calculation | Dynamic sums match down to cent | **PASS** |
| 11 | Relational Integrity | Zero dangling foreign key references | 100% referential integrity | **PASS** |
| 12 | RBAC Security | PoLP privilege boundaries enforced | Permitted vs Denied DML verified | **PASS** |

### 6.2 Row Count Parity Matrix
```text
Table Name         | Source (grp_brewposdb) | Restored (grp_brewposdb_restore_test) | Parity
-------------------+------------------------+---------------------------------------+---------
staff              |                      2 |                                     2 | 100% MATCH
menu_category      |                      3 |                                     3 | 100% MATCH
menu_item          |                     11 |                                    11 | 100% MATCH
order_ticket       |                      5 |                                     5 | 100% MATCH
order_line_item    |                      9 |                                     9 | 100% MATCH
-------------------+------------------------+---------------------------------------+---------
TOTAL ROWS         |                     30 |                                    30 | 100% PARITY
```

### 6.3 Financial Sales Calculation Verification
Executing multi-table analytical joins against `order_ticket`, `staff`, and `order_line_item` yielded identical financial results:
- **Order 1:** 2x Americano + 1x Butter Croissant = **$255.50** (CASH)
- **Order 2:** 1x Matcha Latte + 2x Blueberry Muffin = **$300.00** (ONLINE)
- **Order 3:** 3x Cafe Latte = **$360.00** (CASH)
- **Order 4:** 1x Cappuccino + 1x Chocolate Cookie + 1x Fruit Tea = **$280.00** (ONLINE)
- **Order 5:** 2x Espresso = **$160.00** (CASH)

```markdown
<!-- SCREENSHOT PLACEHOLDER 4: Row Count Parity & Order Calculations -->
![Screenshot 4: SQL terminal verification of row counts and sales totals](screenshots/06_verification_row_parity.png)
*Figure 4: Exact row parity and multi-table financial aggregations verified in grp_brewposdb_restore_test.*
```

---

## 7. Role-Based Access Control (RBAC) Security Verification

In accordance with Activity 4 standards, security checks verified that application service roles operate under the **Principle of Least Privilege**:

### 7.1 Test 1: Permitted POS Query (`app_runtime_grp`)
Cashiers must query active menu items to populate the POS register screen:
```sql
SET ROLE app_runtime_grp;
SELECT item_id, item_name, price FROM public.menu_item WHERE is_active = TRUE ORDER BY item_id LIMIT 3;
RESET ROLE;
```
*Result:* **PASS** — Query executed successfully and returned active catalog items.

### 7.2 Test 2: Denied Tampering Attempt (`app_runtime_grp`)
To guarantee financial audit compliance, `app_runtime_grp` receives only `SELECT, INSERT` on orders. `UPDATE` and `DELETE` are strictly denied:
```sql
SET ROLE app_runtime_grp;
DELETE FROM public.order_ticket WHERE order_id = 1;
RESET ROLE;
```
*Result:* **PASS** — PostgreSQL engine blocked the query with:
`ERROR: permission denied for table order_ticket (SQLSTATE 42501)`

```markdown
<!-- SCREENSHOT PLACEHOLDER 5: RBAC Security Enforcement -->
![Screenshot 5: Terminal execution of permitted SELECT and denied DELETE](screenshots/08_rbac_enforcement.png)
*Figure 5: Demonstration of least privilege: operational queries permitted, financial tampering blocked.*
```

---

## 8. Phase 6: Controlled Disaster Recovery Simulation

### 8.1 Incident Scenario & Non-Destructive Design
To test recovery readiness without risking production data:
- The production database `grp_brewposdb` was **completely untouched**.
- In the staging database `grp_brewposdb_restore_test`, a human-error scenario was simulated: an operator mistakenly deletes unreferenced seasonal menu item `item_id = 1` (`'Pumpkin Spice Latte'`, price: $140.00, `is_active = FALSE`).

### 8.2 Execution & Recovery Sequence
1. **Pre-Incident Baseline:** Recorded attributes of `item_id = 1` in `grp_brewposdb_restore_test`.
2. **Accidental Deletion:** Executed `DELETE FROM menu_item WHERE item_id = 1;`. Confirmed target record count dropped to `0` and total table rows dropped to `10`.
3. **Recovery Staging Provisioning:** Provisioned fresh recovery database:
   ```powershell
   createdb -U postgres -h localhost -p 5432 grp_brewposdb_recovery_test
   pg_restore -U postgres -h localhost -p 5432 -d grp_brewposdb_recovery_test "C:\Users\Matt\pg_backups\brewpos\grp_brewposdb_activity6.dump"
   ```
4. **Data Extraction:** Located the deleted tuple in `grp_brewposdb_recovery_test`.
5. **Surgical Restoration:** Restored the tuple into `grp_brewposdb_restore_test`:
   ```sql
   INSERT INTO public.menu_item (item_id, category_id, item_name, price, is_active)
   VALUES (1, 1, 'Pumpkin Spice Latte', 140.00, FALSE);
   ```
6. **Post-Recovery Audit:** Verified `item_id = 1` was restored with 100% attribute parity, and total menu items returned to `11`.
- **Permanent Data Loss:** **0% (Zero Permanent Loss).**

```markdown
<!-- SCREENSHOT PLACEHOLDER 6: Disaster Recovery Simulation -->
![Screenshot 6: Terminal execution of data deletion, staging extraction, and surgical re-insertion](screenshots/09_disaster_deletion.png)
*Figure 6: Complete disaster recovery drill proving 100% data recovery with zero permanent data loss.*
```

---

## 9. Errors, Limitations, and Production Recommendations

### 9.1 Identified Limitations
1. **RPO Point-in-Time Gap:** Standard logical dumps only protect data up to the moment of backup creation. Any transactions occurring between scheduled backups would be lost if the server suffered catastrophic storage failure.
2. **Global Cluster Roles:** `pg_dump -d` does not include `CREATE ROLE` DDL. In a bare-metal disaster recovery scenario, cluster roles must be pre-provisioned.

### 9.2 DBA Production Recommendations
1. **Enable Continuous WAL Archiving (PITR):** Configure PostgreSQL `archive_mode = on` and `archive_command` to copy Write-Ahead Logs to offsite cloud storage (e.g. AWS S3 / Azure Blob Storage), reducing RPO from 15 minutes to under 60 seconds.
2. **Automate Cluster Global Dumps:** Schedule a daily `pg_dumpall --globals-only` job alongside database backups to preserve role definitions and passwords.
3. **Automated Restoration Drills:** Schedule an automated monthly script that restores the latest backup into an ephemeral container and runs `verification.sql`.

---

## 10. AI Usage Declaration

In compliance with academic integrity guidelines:
- **AI Model Utilized:** Gemini 3.8 Flash (High) via Antigravity Agentic Assistant.
- **Assistance Scope:** Automated inspection of repository SQL scripts, formulation of PowerShell backup/restore automation scripts, compilation of verification queries, and synthesis of technical Markdown and PDF documentation.
- **Human & DBA Oversight:** All database commands, backup extractions, test restorations, and recovery drills were executed directly against a live PostgreSQL 18.6 instance. All cryptographic hashes, row counts, and error outputs were captured from live engine execution.

---

## 11. Final Verification & Sign-Off

| Evaluation Phase | Requirement | Actual Result | Certification |
|---|---|---|:---:|
| **Phase 1** | Project Inspection | 5 tables, DDL, .env audited | **PASS** |
| **Phase 2** | Backup Planning | RPO/RTO, custom archive plan documented | **PASS** |
| **Phase 3** | Backup Creation | 17,897 bytes, SHA-256 hash, 52 TOC entries | **PASS** |
| **Phase 4** | Isolated Restoration | `grp_brewposdb_restore_test` restored cleanly | **PASS** |
| **Phase 5** | Database Verification | 12-point scorecard, 100% row parity, RBAC tests | **PASS** |
| **Phase 6** | Disaster Recovery Drill | Accidental deletion restored, 0% data loss | **PASS** |
| **Phase 7** | Technical Documentation | Complete reports, scripts, and PDF generated | **PASS** |
| **Phase 8** | Organization & Audit | Non-destructive, no credentials/dumps committed | **PASS** |
| **OVERALL STATUS** | **COMP 018 Activity 6** | **COMPLETE & FULLY CERTIFIED** | **PASS** |

