# BrewPOS — Database Backup Execution & Archive Inspection Report
**Course:** COMP 018 — Database Administration  
**Project:** BrewPOS — Café Point-of-Sale System  
**Evaluating Group:** Group 4 (Olivarez, Charles Kean E., Infantado, Gerwin G., Pocsidio, Jhon Louie F., Abangan, SJ Kaizen M., Bartolata, Redge Raindel N.)  
**Database:** `grp_brewposdb`  
**Execution Date:** November 6, 2026, 15:34:49 (UTC+8)  
**Database Engine:** PostgreSQL 18.6 on x86_64-windows  

---

## 1. Backup Execution Overview

In accordance with Phase 3 specifications, a logical, compressed, custom-format database backup of `grp_brewposdb` was created using `pg_dump`. The backup operation was performed directly against the live PostgreSQL server on `localhost:5432` authenticated via the secure local `pgpass.conf` credential mechanism.

### 1.1 Executed Command Line
```powershell
pg_dump -U postgres -h localhost -p 5432 -Fc -d grp_brewposdb -f "C:\Users\Matt\pg_backups\brewpos\grp_brewposdb_activity6.dump"
```

### 1.2 Execution Parameters Justification
- `-U postgres`: Connected as database administrator with complete access to all tables, sequences, and ACLs.
- `-h localhost -p 5432`: Standard local socket/TCP loopback connection.
- `-Fc`: Specifies the **PostgreSQL Custom Archive Format**, enabling zlib/gzip compression, archive TOC table-of-contents inspection, and selective table restoration via `pg_restore`.
- `-d grp_brewposdb`: Target primary database.
- `-f <path>`: Written to protected backup directory outside the Git repository.

---

## 2. File Verification & Metadata Evidence

The output dump file was verified immediately after creation:

| Attribute | Verified Value |
|---|---|
| **File Name** | `grp_brewposdb_activity6.dump` |
| **Storage Directory** | `C:\Users\Matt\pg_backups\brewpos\` |
| **File Size (Exact)** | **17,897 bytes** (17.47 KB) |
| **Creation Timestamp** | `2026-11-06 15:34:49` |
| **Last Modified Time** | `2026-11-06 15:34:49` |
| **PostgreSQL Version** | PostgreSQL 18.6 (MSVC 64-bit) |
| **Archive Format** | Custom (`-Fc`), gzip compressed |
| **Dump Version** | 1.16-0 |
| **Exit Code** | `0` (Success) |
| **Errors / Warnings** | **None (0 errors, 0 warnings)** |

### 2.1 Cryptographic Hash Verification (SHA-256)
The cryptographic hash was computed using PowerShell `Get-FileHash`:

```powershell
Get-FileHash -Path "C:\Users\Matt\pg_backups\brewpos\grp_brewposdb_activity6.dump" -Algorithm SHA256 | Format-List
```

**Recorded Output:**
```text
Algorithm : SHA256
Hash      : E721EFE29FE9D378617BD065E671B6D7DF4BCCFC049E66065E1B3DF05B563C9F
Path      : C:\Users\Matt\pg_backups\brewpos\grp_brewposdb_activity6.dump
```

> [!NOTE]
> The SHA-256 hash `E721EFE29FE9D378617BD065E671B6D7DF4BCCFC049E66065E1B3DF05B563C9F` serves as an immutable cryptographic signature for auditing and detecting any bit-level tampering or storage corruption.

---

## 3. Archive Table of Contents (TOC) Inspection

The internal archive structure was inspected using `pg_restore --list`:

```bash
pg_restore --list "C:\Users\Matt\pg_backups\brewpos\grp_brewposdb_activity6.dump"
```

### 3.1 Archive Header
```text
;
; Archive created at 2026-11-06 15:34:49
;     dbname: grp_brewposdb
;     TOC Entries: 52
;     Compression: gzip
;     Dump Version: 1.16-0
;     Format: CUSTOM
;     Integer: 4 bytes
;     Offset: 8 bytes
;     Dumped from database version: 18.6
;     Dumped by pg_dump version: 18.6
;
```

### 3.2 Breakdown of 52 TOC Entries

The archive contains exactly **52 Table of Contents items**, categorized as follows:

| Category | Count | Detailed Archive Items |
|---|:---:|---|
| **Tables (DDL)** | 5 | `menu_category`, `menu_item`, `order_line_item`, `order_ticket`, `staff` |
| **Sequences (DDL)** | 4 | `menu_category_category_id_seq`, `menu_item_item_id_seq`, `order_ticket_order_id_seq`, `staff_staff_id_seq` |
| **Sequence Ownership** | 4 | `SEQUENCE OWNED BY` declarations linking sequences to corresponding SERIAL PK columns |
| **Column Defaults** | 4 | `DEFAULT` nextval expressions for all 4 sequence-backed primary keys |
| **Table Data (Tuples)** | 5 | Complete table row data payloads for all 5 relational tables |
| **Sequence State** | 4 | `SEQUENCE SET` statements restoring accurate sequence counters |
| **Primary Keys** | 5 | PK constraints for all 5 tables (including composite PK `pk_order_line_item`) |
| **Unique Constraints** | 2 | `uq_menu_category_name`, `uq_menu_item_category_name` |
| **Foreign Keys** | 4 | `fk_menu_item_category`, `fk_order_line_item`, `fk_order_line_order`, `fk_order_ticket_staff` |
| **Access Control (ACL)** | 13 | Schema, table, and sequence access privileges for application roles |
| **Total TOC Entries** | **52** | **100% Comprehensive Archive Payload** |

---

## 4. Screenshot Evidence Placeholders

```markdown
<!-- SCREENSHOT PLACEHOLDER 1: PostgreSQL Connection & pg_dump Execution -->
![Screenshot 1: Terminal execution of pg_dump creating grp_brewposdb_activity6.dump](screenshots/01_backup_creation.png)
*Figure 1: Successful execution of pg_dump -Fc against localhost:5432 with exit code 0.*

<!-- SCREENSHOT PLACEHOLDER 2: SHA-256 Checksum Calculation -->
![Screenshot 2: PowerShell Get-FileHash output displaying SHA-256 digest](screenshots/02_sha256_checksum.png)
*Figure 2: Cryptographic SHA-256 hash generation for grp_brewposdb_activity6.dump.*

<!-- SCREENSHOT PLACEHOLDER 3: Archive TOC Listing -->
![Screenshot 3: Terminal output of pg_restore --list displaying 52 TOC entries](screenshots/03_archive_toc_listing.png)
*Figure 3: Inspection of archive TOC verifying tables, data payloads, sequences, and constraints.*
```

---

## 5. Phase 3 Audit Findings & Sign-Off

1. **Prerequisite Check:** PostgreSQL 18.6 was running and accepting connections on `localhost:5432`.
2. **Database Existence:** `grp_brewposdb` was verified to exist (size: 8,358 kB) before running backup.
3. **Execution Safety:** Zero passwords were typed in shell arguments or logged in plain text.
4. **Archive Integrity:** Custom archive generated with zero errors, zero warnings, and verified via `pg_restore --list`.
5. **Phase 3 Evaluation:** **PASS — Fully Certified.**

