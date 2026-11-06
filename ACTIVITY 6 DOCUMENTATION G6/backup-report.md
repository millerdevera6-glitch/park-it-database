# COMP 018 – Database Administration | Activity 6
## Phase 3: Database Backup Creation and Archive Inspection Report
**Target Database:** `grp00_habalgodb`  
**Host & Port:** `localhost:5432`  
**Database Superuser:** `postgres`  
**Execution Timestamp:** 2026-11-06 17:19:34 PHT  
**Operating System:** Windows (x86_64)  
**PostgreSQL Version:** 18.6  
**Document Author:** Senior PostgreSQL Database Administrator (Student DBA)  

---

## 1. Execution Overview

In accordance with Phase 3 specifications and database safety mandates, a full logical backup of the HabalGo production database (`grp00_habalgodb`) was executed using the PostgreSQL `pg_dump` utility with the Custom Archive format (`-Fc`). 

The backup was staged to an isolated storage location outside the Git repository:
`C:\Users\Matt\.gemini\antigravity\brain\70a3cb86-a366-40fd-a9d0-0fafa69e72d3\scratch\backups\habalgo_activity6.dump`

---

## 2. Backup Execution Command

The backup was generated using the following PowerShell command:

```powershell
& "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe" `
    -U postgres `
    -h localhost `
    -p 5432 `
    -Fc `
    -d grp00_habalgodb `
    -f "C:\Users\Matt\.gemini\antigravity\brain\70a3cb86-a366-40fd-a9d0-0fafa69e72d3\scratch\backups\habalgo_activity6.dump"
```

### Execution Status:
- **Exit Code:** `0` (Success)
- **Standard Error / Warnings:** None. Clean execution without locks or warnings.

---

## 3. Backup File Verification and Cryptographic Integrity

Immediately after generation, the backup file was evaluated for existence, file size, timestamp, and cryptographic hash:

| Metric | Recorded Value |
| :--- | :--- |
| **Backup Filename** | `habalgo_activity6.dump` |
| **Absolute Storage Path** | `C:\Users\Matt\.gemini\antigravity\brain\70a3cb86-a366-40fd-a9d0-0fafa69e72d3\scratch\backups\habalgo_activity6.dump` |
| **Creation Timestamp** | `2026-11-06 17:19:34 PHT` |
| **File Size (Bytes)** | `29,989 bytes` (~29.3 KB) |
| **Hashing Algorithm** | SHA-256 |
| **SHA-256 Hash Digest** | `3CF5A86D91B9854F5D133737BB3ABD8459B99EE1A483C979840C3825518CA2E0` |
| **Git Repository Status** | Staged safely outside repository; excluded by `.gitignore` |

---

## 4. Archive Table of Contents (TOC) Inspection

The integrity and structural composition of the custom dump file were verified using `pg_restore --list`:

```powershell
& "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe" --list "C:\Users\Matt\.gemini\antigravity\brain\70a3cb86-a366-40fd-a9d0-0fafa69e72d3\scratch\backups\habalgo_activity6.dump"
```

### Archive Header Metadata
- **Archive Creation Time:** `2026-11-06 17:19:33`
- **Source Database:** `grp00_habalgodb`
- **Total TOC Entries:** `91`
- **Compression:** `gzip`
- **Archive Format:** `CUSTOM`
- **Server Version:** `18.6`
- **pg_dump Client Version:** `18.6`

### Catalog of Dumped Database Objects

| Category | Count | Verified Objects in TOC |
| :--- | :---: | :--- |
| **Schemas** | 1 | `habalgo` |
| **Tables** | 8 | `booking`, `customer`, `driver`, `driver_vehicle`, `location`, `payment`, `rating_feedback`, `vehicle` |
| **Sequences** | 7 | `customer_customer_id_seq`, `driver_driver_id_seq`, `vehicle_vehicle_id_seq`, `location_location_id_seq`, `booking_booking_id_seq`, `payment_payment_id_seq`, `rating_feedback_rating_id_seq` |
| **Primary Keys** | 8 | `customer_pkey`, `driver_pkey`, `vehicle_pkey`, `driver_vehicle_pkey`, `location_pkey`, `booking_pkey`, `payment_pkey`, `rating_feedback_pkey` |
| **Check Constraints** | 4 | `ck_assignment_dates`, `ck_booking_status`, `payment_amount_check`, `rating_feedback_rating_check` |
| **Unique Keys** | 4 | `customer_email_key`, `driver_license_no_key`, `vehicle_plate_no_key`, `uq_rating_booking_customer` |
| **Foreign Keys** | 9 | `booking_customer_id_fkey`, `booking_driver_id_fkey`, `booking_dropoff_location_id_fkey`, `booking_pickup_location_id_fkey`, `driver_vehicle_driver_id_fkey`, `driver_vehicle_vehicle_id_fkey`, `payment_booking_id_fkey`, `rating_feedback_booking_id_fkey`, `rating_feedback_customer_id_fkey` |
| **Indexes** | 5 | `idx_booking_customer`, `idx_booking_driver`, `idx_booking_date`, `idx_payment_booking`, `idx_rating_booking` |
| **Access Control Lists (ACL)** | 16 | Schema, Table, and Sequence permissions for roles `habalgo_admin`, `habalgo_app`, `habalgo_auditor` |

---

## 5. Verification Conclusion and Safety Confirmation

- **Archive Integrity:** Valid. All 91 entries read without decompression errors.
- **Safety Rule 1 & 2 Adherence:** Original database `grp00_habalgodb` was not dropped, modified, or overwritten.
- **Safety Rule 7 Adherence:** The dump is stored strictly in the external scratch directory and never committed to version control.
- **Outcome:** **PASS**. Ready for Phase 4 isolated test database restoration.

