# Phase 3: PostgreSQL Database Backup and Archive Inspection Report

**Project:** BWIS IT Solutions – Campus Canteen Pre-Order & Queue Management System  
**Target Database:** `canteendb`  
**Execution Timestamp:** 2026-11-06 17:46:37 +08:00  
**DBA Lead:** Senior PostgreSQL Database Administrator  

---

## 1. Backup Execution Summary

A logical backup of the target database `canteendb` was successfully performed using the PostgreSQL `pg_dump` utility with the Custom Archive format (`-Fc`).

### Command Line Executed
```powershell
pg_dump -U postgres -h 127.0.0.1 -p 5432 -Fc -d canteendb -f "C:\Users\Matt\.gemini\antigravity\brain\878ad063-ef98-453d-8141-37794cfa9983\scratch\bwis_activity6.dump"
```

### Environmental Parameters
- **Client Utility Version:** `pg_dump (PostgreSQL) 18.6`
- **Server Engine Version:** `PostgreSQL 18.6 on x86_64-windows`
- **Host / Socket:** `127.0.0.1:5432`
- **Authentication Method:** Local SCRAM-SHA-256 credential resolution via protected `pgpass.conf`
- **Target OS:** Windows 11 (64-bit)

---

## 2. Backup File Metadata & Cryptographic Integrity

| Metric | Recorded Value | Verification Method |
|---|---|---|
| **Archive File Name** | `bwis_activity6.dump` | Filesystem Directory Inspection |
| **Storage Location** | `C:\Users\Matt\.gemini\antigravity\brain\...\scratch\` | Verified strictly **outside** Git workspace |
| **File Size** | **25,798 bytes** (25.19 KB) | `(Get-Item $dumpPath).Length` |
| **SHA-256 Checksum** | `8C89EE1569E27279855B68EF08325F44E60E9796D9211EF89A91B3F433118EAD` | `Get-FileHash -Algorithm SHA256` |
| **Compression Format** | Custom Format with zlib gzip compression | PostgreSQL internal TOC header |
| **Process Exit Code** | `0` (Success, no errors or warnings) | `$LASTEXITCODE` |

---

## 3. Archive Inspection & Table of Contents (TOC) Analysis

The readability and internal integrity of `bwis_activity6.dump` was verified using `pg_restore --list`.

### Command Line Executed
```powershell
pg_restore --list "C:\Users\Matt\.gemini\antigravity\brain\878ad063-ef98-453d-8141-37794cfa9983\scratch\bwis_activity6.dump"
```

### Table of Contents Summary
The archive manifest reported **80 TOC entries** confirming all database entities are captured:

| Category | Count | Captured Database Objects |
|---|---|---|
| **Tables** | 7 | `customer_order`, `menu_item`, `notification`, `order_item`, `queue_entry`, `student`, `vendor` |
| **Sequences** | 7 | `customer_order_order_id_seq`, `menu_item_item_id_seq`, `notification_notification_id_seq`, `order_item_order_item_id_seq`, `queue_entry_queue_id_seq`, `student_student_id_seq`, `vendor_vendor_id_seq` |
| **Sequence Defaults** | 7 | Nextval expressions linking sequences to primary keys |
| **Sequence Set Val** | 7 | Current counter values for all 7 serial sequences |
| **Table Data Blocks** | 7 | Physical data containers for all 7 application tables |
| **Primary Keys & Uniques**| 11 | `customer_order_pkey`, `menu_item_pkey`, `notification_pkey`, `order_item_pkey`, `queue_entry_pkey`, `queue_entry_order_id_key`, `queue_entry_queue_number_queue_date_key`, `student_pkey`, `student_email_key`, `vendor_pkey`, `vendor_email_key` |
| **Foreign Keys** | 7 | All 7 relational integrity foreign key constraints |
| **Access Control Lists (ACL)**| 15 | Object-level security definitions for `canteen_app_grp` and `canteen_readonly_grp` |
| **Schema ACL** | 1 | Access permissions for `SCHEMA public` |

---

## 4. Why a Dump File Alone Does Not Prove Recoverability

A common operational misconception is assuming that a successfully generated dump file (`pg_dump exit 0`) guarantees data recovery. As Senior PostgreSQL DBAs, we emphasize why verification through actual restoration is mandatory:

1. **Storage Subsystem Corruption:** Bit-rot, disk sector degradation, or truncated network transfers can render a dump file unreadable at the moment of disaster.
2. **Missing Global Objects (Roles & Tablespaces):** A database dump does **not** include cluster-wide roles (`canteen_app_grp`, `canteen_readonly_grp`). If the target database server lacks these roles, `pg_restore` will emit severe permission errors and fail to grant object privileges.
3. **Target Version and Collation Incompatibilities:** A dump created on a newer PostgreSQL major version or a different ICU/glibc locale provider may fail to restore on an alternate host unless verified.
4. **Referential and Check Constraint Validation:** Circular dependencies or deferred foreign keys can cause restore failures if dependency resolution fails during data insertion.
5. **Database-Level ACL Stripping:** As demonstrated in Phase 4, single-database dumps do not carry database-level CONNECT privileges, leaving the restored database exposed to unauthorized users unless verified and secured.

---

## 5. Execution Screenshots & Evidence Artifacts

```
[SCREENSHOT PLACEHOLDER 1: Database Connection and Service Health Verification]
Caption: Verification of PostgreSQL 18.6 service status (RUNNING on port 5432).

[SCREENSHOT PLACEHOLDER 2: Custom Format Backup Execution via pg_dump]
Caption: Execution of pg_dump -Fc command targeting canteendb.

[SCREENSHOT PLACEHOLDER 3: Backup File Size and Directory Location]
Caption: Windows Explorer / PowerShell Get-Item confirming 25,798 bytes outside repository.

[SCREENSHOT PLACEHOLDER 4: Cryptographic SHA-256 Checksum Verification]
Caption: Output of Get-FileHash calculating SHA-256 (8C89EE1569E2...).

[SCREENSHOT PLACEHOLDER 5: Archive Manifest Inspection via pg_restore --list]
Caption: Complete 80-entry Table of Contents (TOC) listing all tables, sequences, and ACLs.
```

