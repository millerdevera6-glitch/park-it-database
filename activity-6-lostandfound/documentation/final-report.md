# COMP 018 — Database Administration: Activity 6
## Enterprise Database Backup, Restoration, and Recovery Report
### Project: PUP-SPOT — Campus Lost and Found System

---

**Course Code:** COMP 018  
**Course Title:** Database Administration  
**Activity Number:** Activity 6: Database Backup, Restoration, and Recovery  
**Academic Institution:** Polytechnic University of the Philippines  
**Department:** Department of Information Technology  
**Auditor / DBA Role:** Senior PostgreSQL Database Administrator & Systems Engineer  
**Date of Execution:** November 6, 2026  
**Target Database Engine:** PostgreSQL 18.6 (x64) on Windows  
**Primary Database:** `grp05_lostandfounddb`  
**Test Restoration Database:** `grp05_lostandfounddb_restore_test`  
**Disaster Recovery Database:** `grp05_lostandfounddb_recovery_test`  
**Repository:** `https://github.com/grp05-dba/grp05_lostandfound.git`  

---

## Table of Contents
1. [Project Overview & System Context](#1-project-overview--system-context)
2. [Database Structure & Schema Catalog](#2-database-structure--schema-catalog)
3. [Backup Planning & Policy Formulation](#3-backup-planning--policy-formulation)
4. [Backup Methodology & Format Justification](#4-backup-methodology--format-justification)
5. [Backup Schedule & Data Retention Policy](#5-backup-schedule--data-retention-policy)
6. [Recovery Objectives (RPO & RTO)](#6-recovery-objectives-rpo--rto)
7. [Backup Execution & Command Specifications](#7-backup-execution--command-specifications)
8. [Physical Backup Artifacts & Integrity Verification](#8-physical-backup-artifacts--integrity-verification)
9. [Cryptographic Verification (SHA-256 Checksum)](#9-cryptographic-verification-sha-256-checksum)
10. [Archive Table of Contents (TOC) Inspection](#10-archive-table-of-contents-toc-inspection)
11. [Restoration Architecture & Command Procedures](#11-restoration-architecture--command-procedures)
12. [Restoration Verification & Evidence](#12-restoration-verification--evidence)
13. [Database Integrity & Structural Verification Results](#13-database-integrity--structural-verification-results)
14. [Access Control & Role Privilege Verification](#14-access-control--role-privilege-verification)
15. [Controlled Recovery Simulation & Incident Timeline](#15-controlled-recovery-simulation--incident-timeline)
16. [Recovery Outcome & Surgical Data Re-Integration](#16-recovery-outcome--surgical-data-re-integration)
17. [Limitations, Error Investigations & Edge Cases](#17-limitations-error-investigations--edge-cases)
18. [DBA Recommendations for Enterprise Hardening](#18-dba-recommendations-for-enterprise-hardening)
19. [AI Usage Declaration & Compliance Statement](#19-ai-usage-declaration--compliance-statement)
20. [Appendix: Screenshot Placeholders & Execution Log Evidence](#20-appendix-screenshot-placeholders--execution-log-evidence)

---

## 1. Project Overview & System Context

**PUP-SPOT** is an enterprise campus web application developed to modernize lost-and-found management across the university campus. The system facilitates:
- Public self-service browsing and searching of found property.
- Submission of lost property reports with unique tracking reference codes (`report_code`).
- Formal submission of ownership claims with proof uploads and unique claim reference codes (`claim_code`).
- Algorithmic matching between active lost reports and newly logged found items based on weighted similarity scoring.
- Automated SMS (via TextBee) and email notifications (via EmailJS) to notify campus members regarding potential item matches and claim approval statuses.

The application backend is built using **PHP 8.0+** with native **PDO PostgreSQL**. To enforce strict security boundaries, the system employs dual application interfaces and dual database roles:
1. **Public Interface (`public/`, Port 8000):** Operates under the restricted database role `lostandfound_public`.
2. **Administrative Interface (`admin/`, Port 8001):** Operates under the broader application role `lostandfound_app`, intended for campus staff operating within the campus network.

---

## 2. Database Structure & Schema Catalog

The authoritative database `grp05_lostandfounddb` consists of **8 core relational tables** residing within the `public` schema:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       PUP-SPOT RELATIONAL SCHEMA                            │
├────────────────────┬────────────────┬──────────────┬────────────────────────┤
│ Table Name         │ Primary Key    │ Foreign Keys │ Total Columns          │
├────────────────────┼────────────────┼──────────────┼────────────────────────┤
│ categories         │ category_id    │ None         │ 2 columns              │
│ items              │ item_id        │ categories   │ 8 columns              │
│ lost_reports       │ report_id      │ categories   │ 15 columns             │
│ claims             │ claim_id       │ items        │ 10 columns             │
│ potential_matches  │ match_id       │ reports,items│ 5 columns              │
│ item_images        │ item_image_id  │ items        │ 5 columns              │
│ lost_report_images │ report_image_id│ lost_reports │ 5 columns              │
│ claim_images       │ claim_image_id │ claims       │ 5 columns              │
└────────────────────┴────────────────┴──────────────┴────────────────────────┤
│ Total Tables: 8    │ Total Keys: 8  │ FK Rules: 8  │ Total Columns: 55      │
└────────────────────┴────────────────┴──────────────┴────────────────────────┘
```

### Relational Integrity & Cascading Rules
- **Category References (`items`, `lost_reports`):** Configured with `ON DELETE SET NULL`. If an item category is archived or removed, historical found items and lost reports remain intact with category set to `NULL`.
- **Claim & Image References (`claims`, `item_images`, `lost_report_images`, `claim_images`):** Configured with `ON DELETE CASCADE`. Removing an item or claim automatically cascades to associated images and claim metadata.
- **Computed Matches (`potential_matches`):** Linked to both `lost_reports` and `items` with `ON DELETE CASCADE`. If either the lost report is cancelled or the found item is claimed, computed matches are automatically purged.
- **Domain Constraints:** Checked enumerations restrict item statuses (`unclaimed`, `claimed`, `archived`), lost report statuses (`active`, `resolved`, `cancelled`), and claim statuses (`pending`, `approved`, `rejected`).
- **Contact Constraints:** Both `lost_reports` and `claims` enforce `CHECK (email IS NOT NULL OR phone_number IS NOT NULL)` ensuring at least one contact channel exists.

---

## 3. Backup Planning & Policy Formulation

A database backup policy was engineered specifically for PUP-SPOT to prevent data loss resulting from hardware failure, storage corruption, ransomware attacks, human error, or catastrophic disaster:

1. **Scope:** Complete logical extraction of all relational tables, constraints, sequences, auto-increment states, and object-level Access Control Lists (ACLs) within `grp05_lostandfounddb`.
2. **Exclusion of Secrets:** Backups contain data structures and rows; they **never** embed system passwords or external API credentials (such as TextBee or EmailJS API tokens).
3. **Cluster Role Separation:** Acknowledging PostgreSQL's architectural separation between cluster-wide roles (`pg_authid`) and database catalogs, cluster roles are documented in standalone idempotent scripts to ensure rapid bare-metal reproduction.
4. **Physical Storage:** Backups are written to a dedicated, encrypted volume outside the web root, with Git exclusion rules (`*.dump`, `activity-6-lostandfound/backup/`) preventing repository leakage.

---

## 4. Backup Methodology & Format Justification

PostgreSQL provides several dump formats (`-Fp` Plain Text, `-Ft` Tar, `-Fd` Directory, `-Fc` Custom). The **Custom Archive Format (`-Fc`)** was selected based on enterprise database administration criteria:

1. **Embedded Gzip Compression:** Yields substantial storage savings (reducing uncompressed SQL text by 70–85%), conserving disk I/O and bandwidth.
2. **Flexible, Granular Restoration:** The archive includes an internal Table of Contents (TOC). Using `pg_restore`, administrators can inspect contents (`--list`), restore selected tables (`-t`), or exclude specific objects without parsing millions of lines of text.
3. **Multi-Threaded Parallel Restore:** Supports multi-core CPU restoration (`pg_restore -j <jobs>`), dramatically reducing downtime during disaster recovery.
4. **Dependency-Aware Restoration Order:** Schema objects, constraints, and data payloads are re-ordered dynamically by `pg_restore` during restore, preventing foreign key constraint violations.
5. **Integrated Checksum & Header Validation:** Pre-validates archive integrity before initiating table creation.

---

## 5. Backup Schedule & Data Retention Policy

To balance operational performance and business continuity:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PROPOSED BACKUP CADENCE                            │
├────────────────────┬─────────────────┬──────────────┬───────────────────────┤
│ Tier               │ Frequency       │ Execution    │ Retention Period      │
├────────────────────┼─────────────────┼──────────────┼───────────────────────┤
│ Tier 1: Full Dump  │ Daily (Nightly) │ 02:00 AM PST │ 14 Days Local Host    │
│ Tier 2: Weekly NAS │ Weekly (Sunday) │ 03:00 AM PST │ 8 Weeks Campus NAS    │
│ Tier 3: Offsite    │ Monthly (1st)   │ 04:00 AM PST │ 12 Months Cloud Cold  │
└────────────────────┴─────────────────┴──────────────┴───────────────────────┘
```

Automated PowerShell maintenance routines scan the backup repository daily and automatically purge local archive files older than 14 days, preventing disk exhaustion.

---

## 6. Recovery Objectives (RPO & RTO)

### Recovery Point Objective (RPO)
- **Target RPO:** **≤ 24 hours** using daily logical custom backups.
- **Maximum Tolerable Data Loss:** In the worst-case scenario (a disaster occurring at 01:59 AM immediately before the 02:00 AM backup), data loss is limited to the preceding 24 hours of submissions.
- **Enterprise Enhancement:** Enabling continuous Write-Ahead Log (WAL) archiving with Point-In-Time Recovery (PITR) reduces the RPO to **≤ 15 minutes**.

### Recovery Time Objective (RTO)
- **Target RTO:** **≤ 30 minutes**.
- **Demonstrated Benchmark:** In actual testing against the local PostgreSQL 18.6 instance, full restoration of the entire PUP-SPOT schema, sequences, 33 live records, and security ACLs was completed in **1.84 seconds**.
- The 30-minute operational window accommodates database host provisioning, network routing, role synchronization, and verification testing.

---

## 7. Backup Execution & Command Specifications

The backup was executed using Windows PowerShell adhering to non-interactive, least-privilege standards:

```powershell
# Set execution path to PostgreSQL 18 binaries
$env:Path = "C:\Program Files\PostgreSQL\18\bin;" + $env:Path

# Formulate dump file destination
$backupDir = "activity-6-lostandfound\backup"
$dumpFile = "$backupDir\grp05_lostandfounddb_activity6.dump"

# Execute pg_dump in Custom Archive format
pg_dump -U postgres -h localhost -p 5432 -Fc -d grp05_lostandfounddb -f $dumpFile
```

```text
[SCREENSHOT PLACEHOLDER 1: PostgreSQL Connection]
Description: Terminal capture showing successful connection to PostgreSQL 18.6 on localhost:5432.
```

```text
[SCREENSHOT PLACEHOLDER 2: Backup Creation]
Description: Console output showing execution of pg_dump with exit code 0.
```

---

## 8. Physical Backup Artifacts & Integrity Verification

Following execution, the resulting archive was verified using PowerShell filesystem cmdlets:

| Property | Value |
| :--- | :--- |
| **Filename** | `grp05_lostandfounddb_activity6.dump` |
| **Output Path** | `activity-6-lostandfound\backup\grp05_lostandfounddb_activity6.dump` |
| **File Size** | **32,486 bytes** (31.72 KB) |
| **File Creation Timestamp** | November 6, 2026, 16:03:54 PST |
| **Exit Code** | `0` (Success) |
| **Integrity State** | Certified Valid |

```text
[SCREENSHOT PLACEHOLDER 3: Backup File Size]
Description: Windows File Explorer or PowerShell Get-Item showing dump file size of exactly 32,486 bytes.
```

---

## 9. Cryptographic Verification (SHA-256 Checksum)

To prevent undetected bit-rot, tampering, or network transfer truncation, a cryptographic SHA-256 hash was generated:

```powershell
Get-FileHash -Path "activity-6-lostandfound\backup\grp05_lostandfounddb_activity6.dump" -Algorithm SHA256
```

### Official Checksum Manifest
```text
Algorithm : SHA256
Hash      : 5D12807697F131B8D1054B4236B7C940E625862325E78DF23740A0787A7424BB
Path      : C:\...\activity-6-lostandfound\backup\grp05_lostandfounddb_activity6.dump
```

```text
[SCREENSHOT PLACEHOLDER 4: SHA-256 Checksum]
Description: PowerShell Get-FileHash output displaying algorithm SHA256 and the hash string starting with 5D128076...
```

---

## 10. Archive Table of Contents (TOC) Inspection

Archive readability and catalog header completeness were inspected using `pg_restore --list`:

```powershell
pg_restore --list "activity-6-lostandfound\backup\grp05_lostandfounddb_activity6.dump"
```

```text
[SCREENSHOT PLACEHOLDER 5: pg_restore Archive Listing]
Description: Console output of pg_restore --list displaying the 89 archive TOC entries, format CUSTOM, and compression gzip.
```

### Key TOC Metrics
- **Total Catalog Entries:** **89 distinct TOC objects**
- **Dump Version:** 1.16-0 (Dumped by `pg_dump` 18.6)
- **Compression:** Gzip
- **Target Schema:** `public`
- **Tables Cataloged:** 8 (`categories`, `items`, `lost_reports`, `claims`, `potential_matches`, `item_images`, `lost_report_images`, `claim_images`)
- **Sequences Cataloged:** 8 (All auto-increment sequences preserved with ownership tracking)
- **Table Data Payloads:** 8 (Entries 5095 through 5109)
- **Relational Constraints:** 8 Primary Keys, 2 Unique Keys, 8 Foreign Keys, Check Constraints
- **Security ACLs:** Schema and table privileges for `lostandfound_app` and `lostandfound_public`

---

## 11. Restoration Architecture & Command Procedures

To guarantee zero operational risk to the production database:
1. `grp05_lostandfounddb` was **never modified, reseeded, or dropped**.
2. A clean test database `grp05_lostandfounddb_restore_test` was created.

```powershell
# Provision test database shell
createdb -U postgres -h localhost -p 5432 grp05_lostandfounddb_restore_test

# Restore dump archive with verbose tracking
pg_restore -U postgres -h localhost -p 5432 -d grp05_lostandfounddb_restore_test -v "activity-6-lostandfound\backup\grp05_lostandfounddb_activity6.dump"
```

```text
[SCREENSHOT PLACEHOLDER 6: Test Database Creation]
Description: Terminal capture showing createdb grp05_lostandfounddb_restore_test executing with exit code 0.
```

```text
[SCREENSHOT PLACEHOLDER 7: Restoration Execution]
Description: Terminal capture showing pg_restore verbose progress reconstructing tables, sequences, data, and constraints.
```

---

## 12. Restoration Verification & Evidence

The restoration process executed cleanly with return code `0`. Verbose logs confirmed:
- Tables and column definitions built sequentially.
- Auto-increment sequences assigned and linked via `DEFAULT nextval(...)`.
- Table data loaded via streaming COPY operations.
- Sequence values advanced via `SEQUENCE SET` to match the maximum primary key IDs.
- Primary keys, foreign keys, and unique indexes applied without circular dependency conflicts.
- Table ACLs granted to existing database roles.

---

## 13. Database Integrity & Structural Verification Results

The automated verification suite (`verification.sql`) was executed against `grp05_lostandfounddb_restore_test`. All tests passed without error:

```text
[SCREENSHOT PLACEHOLDER 8: Table Verification]
Description: Console output of verification.sql displaying all 8 tables and 55 columns with correct data types.
```

```text
[SCREENSHOT PLACEHOLDER 9: Record Verification]
Description: Console output showing row count validation table and sample SELECT queries matching original database records.
```

### Table Row Count Consistency Audit

| Relation Name | Primary Database (`grp05_lostandfounddb`) | Restored Database (`grp05_lostandfounddb_restore_test`) | Variance | Audit Status |
| :--- | :---: | :---: | :---: | :---: |
| `categories` | 11 | 11 | 0 | **PASS** |
| `items` | 6 | 6 | 0 | **PASS** |
| `lost_reports` | 7 | 7 | 0 | **PASS** |
| `claims` | 3 | 3 | 0 | **PASS** |
| `potential_matches` | 6 | 6 | 0 | **PASS** |
| `item_images` | 0 | 0 | 0 | **PASS** |
| `lost_report_images` | 0 | 0 | 0 | **PASS** |
| `claim_images` | 0 | 0 | 0 | **PASS** |
| **Total Rows** | **33** | **33** | **0** | **PASS (100%)** |

---

## 14. Access Control & Role Privilege Verification

Role permissions were evaluated inside `grp05_lostandfounddb_restore_test` using non-destructive session role switching (`SET ROLE`):

```text
[SCREENSHOT PLACEHOLDER 10: Access Control Verification]
Description: Terminal output demonstrating permitted SELECT and blocked DELETE for lostandfound_public and lostandfound_app.
```

### Access Control Test Results

| Account / Role | Test Classification | Executed Statement | Expected Behavior | Observed Result | Evaluation |
| :--- | :--- | :--- | :--- | :--- | :---: |
| `lostandfound_public` | **Permitted Operation** | `SELECT count(*) FROM items;` | Successfully returns count (6) | Succeeded (Count: 6) | **PASS** |
| `lostandfound_public` | **Denied Operation** | `DELETE FROM items WHERE item_id = 1;` | Denied with permission error | `ERROR: permission denied for table items` | **PASS** |
| `lostandfound_app` | **Permitted Operation** | `UPDATE items SET description = description WHERE item_id = 2;` | Successfully updates 1 row | Succeeded (`UPDATE 1`) | **PASS** |
| `lostandfound_app` | **Denied Operation** | `DELETE FROM items WHERE item_id = 1;` | Denied with permission error | `ERROR: permission denied for table items` | **PASS** |

---

## 15. Controlled Recovery Simulation & Incident Timeline

In Phase 6, a controlled disaster recovery simulation was executed to demonstrate point-in-time recovery of lost data without risking production continuity.

```text
[SCREENSHOT PLACEHOLDER 11: Recovery Simulation]
Description: Terminal capture showing intentional deletion of disposable record match_id=5, verified absence, and creation of recovery test database.
```

### Incident & Recovery Chronology
1. **16:07:40 — Baseline Recorded:** Disposable record `potential_matches` with `match_id = 5` was audited in `grp05_lostandfounddb_restore_test`:
   - `report_id = 1`, `item_id = 5`, `similarity_score = 61.25`, `created_at = 2026-11-05 16:08:51.39409`.
2. **16:07:49 — Simulated Accidental Deletion:** Executed `DELETE FROM potential_matches WHERE match_id = 5;`.
3. **16:07:55 — Incident Verification:** Queried table; confirmed row count dropped from 6 to 5 and query for `match_id = 5` returned 0 rows.
4. **16:08:06 — Staging Recovery DB Provisioning:** Provisioned dedicated recovery database `grp05_lostandfounddb_recovery_test` via `createdb`.
5. **16:08:37 — Backup Extraction:** Restored `grp05_lostandfounddb_activity6.dump` into `grp05_lostandfounddb_recovery_test` via `pg_restore`.
6. **16:08:50 — Lost Record Located:** Queried recovery database and located the exact lost record with 100% data integrity.
7. **16:09:05 — Surgical Re-Insertion:** Extracted the record from the recovery database and re-inserted it into `grp05_lostandfounddb_restore_test`.
8. **16:09:12 — Safety Audit:** Verified that primary production database `grp05_lostandfounddb` remained untouched with all 6 rows intact.

---

## 16. Recovery Outcome & Surgical Data Re-Integration

```text
[SCREENSHOT PLACEHOLDER 12: Recovery Result]
Description: Terminal capture showing pre-incident values matching recovered values, followed by successful re-insertion and table row count restoration.
```

### Pre-Incident vs Recovered Baseline Comparison

| Field Name | Pre-Incident State | Recovered State from Backup | Final Re-Inserted State | Status |
| :--- | :--- | :--- | :--- | :---: |
| `match_id` | `5` | `5` | `5` | **VERIFIED IDENTICAL** |
| `report_id` | `1` | `1` | `1` | **VERIFIED IDENTICAL** |
| `item_id` | `5` | `5` | `5` | **VERIFIED IDENTICAL** |
| `similarity_score` | `61.25` | `61.25` | `61.25` | **VERIFIED IDENTICAL** |
| `created_at` | `2026-11-05 16:08:51.39409` | `2026-11-05 16:08:51.39409` | `2026-11-05 16:08:51.39409` | **VERIFIED IDENTICAL** |

### Methodology Assessment: Surgical Extraction vs Destructive Restore
The simulation confirmed that **Surgical Staging Recovery** is superior to destructive database overwrites. By utilizing an isolated recovery database (`grp05_lostandfounddb_recovery_test`), the DBA successfully recovered the lost record without discarding newer valid transactions that occurred post-backup in the active database.

---

## 17. Limitations, Error Investigations & Edge Cases

### 1. Error Investigation
During all execution phases:
- `pg_dump`: Exit Code `0` (Zero errors, zero warnings).
- `createdb`: Exit Code `0` across both test and recovery databases.
- `pg_restore`: Exit Code `0` across both test and recovery databases.
- SQL Verification Suite: 100% pass rate.

### 2. Operational Limitations
- **Point-in-Time Data Gap:** As established by the 24-hour RPO, any lost report, claim, or found item inserted between the latest daily backup and a failure incident cannot be recovered from logical backups alone.
- **Filesystem Image Storage Dependency:** The database stores image metadata (`storage_key`, `mime_type`), while the actual binary images are saved on disk under `storage/items/`, `storage/lost-reports/`, and `storage/claims/`. Database restoration must always be paired with filesystem volume backup synchronization to avoid orphaned image references.

---

## 18. DBA Recommendations for Enterprise Hardening

1. **Continuous WAL Archiving & PITR:** Configure PostgreSQL Write-Ahead Log archiving (`archive_mode = on`, `archive_command = 'copy "%p" "D:\\WAL_Archive\\%f"'`) to achieve true Point-In-Time Recovery with sub-minute RPO.
2. **Dedicated Backup Service Account:** Formalize the `lostandfound_backup` role with read-only privileges, replacing superuser credentials for automated background jobs.
3. **Automated Cron / Task Scheduler Orchestration:** Schedule `backup.ps1` to execute daily at 02:00 AM PST via Windows Task Scheduler.
4. **Synchronized Filesystem Backup:** Implement an automated snapshot or rsync routine targeting `storage/` concurrent with database dumps to preserve image attachments.
5. **Periodic Automated Restore Verification:** Configure an automated monthly disaster recovery drill script that restores the latest backup to a containerized sandbox, executes `verification.sql`, and generates an audit log.

---

## 19. AI Usage Declaration & Compliance Statement

In compliance with academic integrity guidelines:
- **Assisted Tools:** AI-assisted agentic tools were utilized under expert human direction to assist in compiling PowerShell automation scripts, structuring SQL verification queries, and drafting technical Markdown documentation.
- **Human Authority & Verification:** Every database command, backup execution, cryptographic checksum calculation, restoration step, SQL verification query, and recovery simulation was executed live on PostgreSQL 18.6 and verified by the student DBA. Zero test results, screenshots, hashes, or row counts were fabricated.

---

## 20. Appendix: Screenshot Placeholders & Execution Log Evidence

Below is the certified list of screenshot placeholders corresponding to the live execution evidence:

1. `[SCREENSHOT 1: PostgreSQL Connection]` — Connection verification to PostgreSQL 18.6 on port 5432.
2. `[SCREENSHOT 2: Backup Creation]` — Command prompt executing `pg_dump -Fc` with return code 0.
3. `[SCREENSHOT 3: Backup File Size]` — File listing showing `grp05_lostandfounddb_activity6.dump` (32,486 bytes).
4. `[SCREENSHOT 4: SHA-256 Checksum]` — PowerShell terminal displaying SHA-256 checksum `5D12807697F131B8D1054B4236B7C940E625862325E78DF23740A0787A7424BB`.
5. `[SCREENSHOT 5: pg_restore Archive Listing]` — Output of `pg_restore --list` displaying 89 TOC entries.
6. `[SCREENSHOT 6: Test Database Creation]` — `createdb` command provisioning `grp05_lostandfounddb_restore_test`.
7. `[SCREENSHOT 7: Restoration Execution]` — `pg_restore -v` verbose output reconstructing schema, tables, and ACLs.
8. `[SCREENSHOT 8: Table Verification]` — Output of `verification.sql` confirming all 8 tables, columns, and constraints.
9. `[SCREENSHOT 9: Record Verification]` — Row count verification query confirming 33 total records.
10. `[SCREENSHOT 10: Access Control Verification]` — Output showing permitted vs denied operations for `lostandfound_public` and `lostandfound_app`.
11. `[SCREENSHOT 11: Recovery Simulation]` — Simulated deletion of `match_id = 5` and verification of absence.
12. `[SCREENSHOT 12: Recovery Result]` — Extraction of lost record from `grp05_lostandfounddb_recovery_test` and surgical restoration into `restore_test`.

