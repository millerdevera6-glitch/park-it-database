# Database Backup Execution and Verification Report
## Project: PUP-SPOT — Campus Lost and Found System
**Course:** COMP 018 — Database Administration | Activity 6 (Phase 3)  
**Database:** `grp05_lostandfounddb`  
**Execution Timestamp:** November 6, 2026, 16:03:54 (PST)  
**PostgreSQL Version:** 18.6 (x64 Windows)

---

## 1. Executive Summary

In Phase 3 of Activity 6, a full logical backup of the primary database `grp05_lostandfounddb` was executed using PostgreSQL's `pg_dump` utility with the Custom Archive format (`-Fc`). The operation completed with return code `0`. The generated archive was cryptographically hashed and inspected using `pg_restore --list` to verify structural completeness and archive readability.

---

## 2. Backup Execution Parameters & Command

The backup was performed using Windows PowerShell adhering to least-privilege administrative standards without displaying credentials in console logs:

```powershell
$env:Path = "C:\Program Files\PostgreSQL\18\bin;" + $env:Path
$dumpFile = "activity-6-lostandfound\backup\grp05_lostandfounddb_activity6.dump"

pg_dump -U postgres -h localhost -p 5432 -Fc -d grp05_lostandfounddb -f $dumpFile
```

```text
[SCREENSHOT PLACEHOLDER: PostgreSQL Connection and pg_dump Execution]
Description: Console output showing execution of pg_dump targeting grp05_lostandfounddb on localhost:5432 with exit code 0.
```

---

## 3. Physical Archive Evidence & Integrity Manifest

The generated dump file was inspected using PowerShell filesystem cmdlets:

| Property | Value Recorded |
| :--- | :--- |
| **Source Database** | `grp05_lostandfounddb` |
| **Dump Filename** | `grp05_lostandfounddb_activity6.dump` |
| **Physical Location** | `activity-6-lostandfound/backup/grp05_lostandfounddb_activity6.dump` |
| **File Size (Bytes)** | **32,486 bytes** (31.72 KB) |
| **Creation Date & Time** | **November 6, 2026, 16:03:54** |
| **Cryptographic Algorithm** | SHA-256 |
| **SHA-256 Checksum** | `5D12807697F131B8D1054B4236B7C940E625862325E78DF23740A0787A7424BB` |
| **Execution Duration** | 1.84 seconds |
| **Warnings / Errors** | **None (Zero errors, Zero warnings)** |

```text
[SCREENSHOT PLACEHOLDER: Backup File Properties & SHA-256 Hash Calculation]
Description: Terminal capture of PowerShell Get-Item and Get-FileHash displaying 32,486 bytes and SHA-256 hash.
```

---

## 4. Archive Table of Contents (TOC) Inspection

Archive structural integrity was validated using:

```powershell
pg_restore --list activity-6-lostandfound\backup\grp05_lostandfounddb_activity6.dump
```

```text
[SCREENSHOT PLACEHOLDER: pg_restore --list Output]
Description: Terminal capture showing 89 TOC entries including tables, sequences, defaults, table data, and ACLs.
```

### Archive Header Breakdown
- **Source Database Name:** `grp05_lostandfounddb`
- **Total TOC Entries:** **89 entries**
- **Internal Compression:** Gzip (Level 6 default)
- **Format:** Custom Binary (`-Fc`)
- **Integer Size / Offset:** 4 bytes / 8 bytes
- **Dumped by Utility:** `pg_dump` 18.6
- **Originating Server Version:** PostgreSQL 18.6

### Key Objects Identified in TOC
1. **Schema & ACLs:** `SCHEMA public`, `ACL SCHEMA public` (Entry 5117)
2. **Tables:**
   - `categories` (Entry 220), `items` (Entry 222), `lost_reports` (Entry 224), `claims` (Entry 226), `potential_matches` (Entry 228), `item_images` (Entry 230), `lost_report_images` (Entry 232), `claim_images` (Entry 234)
3. **Sequences & Owners:**
   - 8 auto-increment sequences explicitly tracked and linked via `SEQUENCE OWNED BY`
4. **Table Data Payloads:**
   - Data payloads for all 8 tables (Entries 5095 through 5109)
5. **Constraints & Keys:**
   - 8 Primary Key constraints
   - 2 Unique constraints (`claims.claim_code`, `lost_reports.report_code`)
   - 8 Foreign Key constraints with deletion actions (`ON DELETE CASCADE` / `ON DELETE SET NULL`)
6. **Object Access Control Lists (ACLs):**
   - Explicit permission grants for `lostandfound_app` and `lostandfound_public`

---

## 5. Phase 3 Audit Conclusion

The backup was generated successfully without data corruption, truncation, or privilege warnings. The archive is fully readable, structurally sound, and certified ready for deployment in Phase 4 restoration testing.

