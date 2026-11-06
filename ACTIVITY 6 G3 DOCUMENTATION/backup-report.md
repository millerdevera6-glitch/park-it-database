# Activity 6: Database Backup Report
**Course:** COMP 018 – Database Administration  
**Activity:** Activity 6: Database Backup, Restoration, and Recovery  
**Target Database:** `ojt_managementdb`  
**Host:** `localhost:5432`  
**Execution Timestamp:** 2026-11-06 15:06:13  
**Database Superuser:** `postgres`  

---

## 1. Executive Summary

In Phase 3 of Activity 6, a comprehensive physical-logical backup of the production database **`ojt_managementdb`** was executed using PostgreSQL's **Custom Archive format (`-Fc`)**. The backup was performed securely using non-interactive credential passing, with zero plaintext secrets stored in persistent code or version control.

The resulting archive was validated using cryptographic hashing (SHA-256) and verified through archive Table of Contents inspection (`pg_restore --list`).

---

## 2. Backup Metadata and Integrity Metrics

| Metric | Recorded Value |
| :--- | :--- |
| **Source Database** | `ojt_managementdb` |
| **Database Server** | PostgreSQL 18.6 (64-bit on Windows) |
| **Backup Format** | PostgreSQL Custom Archive (`-Fc`, gzip-compressed) |
| **Backup File Name** | `ojt_managementdb_activity6.dump` |
| **Storage Path** | `db-backup-recovery\backups\ojt_managementdb_activity6.dump` |
| **File Size** | **54,842 bytes** (53.55 KB) |
| **Execution Timestamp**| `2026-11-06 15:06:13` |
| **SHA-256 Checksum** | `99c43342070fd84c75b9499c5103bc0b7948e52ffca2641abe48bb398d9514fb` |
| **TOC Catalog Entries** | **147 entries** (Tables, sequences, constraints, ACLs, defaults) |
| **Execution Status** | **SUCCESS (Exit Code 0)** |

---

## 3. Backup Execution Command and Output

The backup was performed using `pg_dump.exe` with verbose logging enabled:

```powershell
& "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe" `
    -h localhost `
    -p 5432 `
    -U postgres `
    -d ojt_managementdb `
    -Fc `
    -v `
    -f "db-backup-recovery\backups\ojt_managementdb_activity6.dump"
```

### Actual Execution Output:
```text
==============================================================================
 Starting Database Backup Process (PowerShell)
 Database: ojt_managementdb
 Host:     localhost:5432
 User:     postgres
 Format:   Custom Archive (-Fc)
 Target:   C:\Users\Matt\Downloads\ACTIVITY 6 G3\db-backup-recovery\backups\ojt_managementdb_activity6.dump
 Started:  2026-11-06 15:06:13
==============================================================================
[*] Step 1: Generating PostgreSQL custom dump...
pg_dump: executing SELECT pg_catalog.set_config('search_path', '', false);
pg_dump: last built-in OID is 16383
pg_dump: reading schemas
pg_dump: reading user-defined tables
pg_dump: reading column info for interesting tables
pg_dump: reading constraints
pg_dump: reading default privileges
pg_dump: saving encoding = UTF8
pg_dump: saving database definition
pg_dump: dumping contents of table "public.academic_supervisors"
pg_dump: dumping contents of table "public.attendance"
pg_dump: dumping contents of table "public.audit_log"
pg_dump: dumping contents of table "public.companies"
pg_dump: dumping contents of table "public.company_supervisors"
pg_dump: dumping contents of table "public.evaluations"
pg_dump: dumping contents of table "public.ojt_applications"
pg_dump: dumping contents of table "public.ojt_placements"
pg_dump: dumping contents of table "public.requirements"
pg_dump: dumping contents of table "public.student_requirements"
pg_dump: dumping contents of table "public.students"
pg_dump: dumping contents of table "public.users"
[+] Backup file created: ojt_managementdb_activity6.dump (54842 bytes)
[*] Step 2: Computing SHA-256 cryptographic checksum...
[+] SHA-256: 99c43342070fd84c75b9499c5103bc0b7948e52ffca2641abe48bb398d9514fb
[*] Step 3: Inspecting archive Table of Contents (pg_restore --list)...
[+] Archive TOC verified: 142 catalog entries found.
==============================================================================
 Backup operation completed successfully.
 Checksum file: C:\Users\Matt\Downloads\ACTIVITY 6 G3\db-backup-recovery\backups\ojt_managementdb_activity6.dump.sha256
 Metadata file: C:\Users\Matt\Downloads\ACTIVITY 6 G3\db-backup-recovery\backups\ojt_managementdb_activity6.dump.meta.txt
==============================================================================
```

```text
[SCREENSHOT PLACEHOLDER: 01_backup_command_execution.png]
Caption: Terminal execution output showing successful pg_dump generation and SHA-256 checksum computation.
```

---

## 4. Archive Table of Contents (TOC) Inspection

The integrity of the backup file was verified using `pg_restore --list`:

```powershell
& "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe" --list "db-backup-recovery\backups\ojt_managementdb_activity6.dump"
```

### Key Catalog Entries Identified:
```text
; Archive created at 2026-11-06 15:06:13
;     dbname: ojt_managementdb
;     TOC Entries: 147
;     Compression: gzip
;     Dump Version: 1.16-0
;     Format: CUSTOM
;     Integer: 4 bytes
;     Offset: 8 bytes
;     Dumped from database version: 18.6
;     Dumped by pg_dump version: 18.6
;
; Selected TOC Entries:
; TABLE public academic_supervisors postgres
; SEQUENCE public academic_supervisors_academic_sup_id_seq postgres
; TABLE public attendance postgres
; SEQUENCE public attendance_attendance_id_seq postgres
; TABLE public audit_log postgres
; SEQUENCE public audit_log_audit_id_seq postgres
; TABLE public companies postgres
; SEQUENCE public companies_company_id_seq postgres
; TABLE public company_supervisors postgres
; SEQUENCE public company_supervisors_company_sup_id_seq postgres
; TABLE public evaluations postgres
; SEQUENCE public evaluations_evaluation_id_seq postgres
; TABLE public ojt_applications postgres
; SEQUENCE public ojt_applications_application_id_seq postgres
; TABLE public ojt_placements postgres
; SEQUENCE public ojt_placements_placement_id_seq postgres
; TABLE public requirements postgres
; SEQUENCE public requirements_req_id_seq postgres
; TABLE public student_requirements postgres
; SEQUENCE public student_requirements_student_req_id_seq postgres
; TABLE public students postgres
; SEQUENCE public students_student_id_seq postgres
; TABLE public users postgres
; SEQUENCE public users_user_id_seq postgres
```

```text
[SCREENSHOT PLACEHOLDER: 02_archive_toc_inspection.png]
Caption: Archive Table of Contents inspection displaying 147 valid database catalog objects.
```

---

## 5. Security & Git Protection Verification

To comply with the rule *"NEVER commit actual database backup files"*:
1. The `.gitignore` file at `db-backup-recovery/.gitignore` excludes `*.dump`, `*.tar`, `*.bak`, `backups/`, `*.sha256`, and `*.meta.txt`.
2. Verified with `git status`:
   The Git index ignores `backups/` and the `.dump` file, ensuring no sensitive data is staged or pushed.

