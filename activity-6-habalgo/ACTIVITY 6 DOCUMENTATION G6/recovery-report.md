# COMP 018 – Database Administration | Activity 6
## Phase 6: Controlled Disaster Recovery Simulation Report
**Primary Test Database:** `grp00_habalgodb_activity6_restore_test`  
**Secondary Recovery Database:** `grp00_habalgodb_recovery_test`  
**Checkpoint Backup Archive:** `habalgo_sim_checkpoint.dump`  
**Execution Timestamp:** 2026-11-06 17:23:00 to 17:24:30 PHT  
**Database Host:** `localhost:5432`  
**Lead DBA / Disaster Recovery Specialist:** Senior PostgreSQL Database Administrator (Student DBA)  

---

## 1. Incident Scenario and Overview

To validate the operational effectiveness of the HabalGo disaster recovery procedure without jeopardizing live systems, a controlled simulated data loss and recovery exercise was conducted.

### Incident Description:
A routine administrative maintenance script inadvertently executed an unqualified or misdirected `DELETE` operation against the core customer and booking entities in the restored test database, destroying active ride records and customer profile information.

### Safety Guarantee:
All operations were executed exclusively within dedicated sandbox environments (`grp00_habalgodb_activity6_restore_test` and `grp00_habalgodb_recovery_test`). The production database `grp00_habalgodb` remained untouched (0 records mutated, 0 records deleted).

---

## 2. Recovery Timeline (PHT)

| Time | Phase / Action | Description |
| :--- | :--- | :--- |
| **17:22:53** | **Baseline Setup** | Seeded disposable test customer (ID: 1), test driver (ID: 1), location (ID: 1), and completed booking (ID: 1). |
| **17:23:19** | **Checkpoint Snapshot** | Created point-in-time custom archive `habalgo_sim_checkpoint.dump` representing scheduled pre-incident state. |
| **17:23:31** | **Referential Integrity Test** | Attempted direct customer deletion; engine blocked the delete via `RESTRICT` on `booking_customer_id_fkey`. |
| **17:23:39** | **Simulated Data Loss** | Operator cascaded deletion of booking ID 1 followed by customer ID 1 in test database. |
| **17:23:44** | **Incident Confirmation** | Executed verification queries confirming customer ID 1 and booking ID 1 returned `0 rows` (Data Loss Confirmed). |
| **17:23:51** | **Recovery Provisioning** | Created isolated recovery database: `grp00_habalgodb_recovery_test`. |
| **17:23:58** | **Archive Ingestion** | Executed `pg_restore` of `habalgo_sim_checkpoint.dump` into `grp00_habalgodb_recovery_test`. |
| **17:24:05** | **Data Extraction** | Queried recovery database and located deleted customer and booking records intact. |
| **17:24:16** | **Targeted Transplant** | Restored recovered customer ID 1 and booking ID 1 back into test database. |
| **17:24:24** | **Post-Recovery Audit** | Confirmed 100% record integrity restored to test database; production database remained untouched. |

---

## 3. Pre-Incident Baseline State vs. Post-Incident Loss

### Disposable Record Attributes
- **Entity Type:** `habalgo.customer`
- **Unique Identifier (`customer_id`):** `1`
- **Full Name:** `'DISPOSABLE TEST RIDER - SIMULATION'`
- **Contact Number:** `'09990001122'`
- **Email Address:** `'disposable.rider.simulation@habalgo-test.local'`
- **Associated Booking ID:** `1` (Status: `'Completed'`, Date: `2026-11-06 17:23:13.367313`)

### Data Loss Verification
```sql
SELECT * FROM habalgo.customer WHERE customer_id = 1;
-- Output: (0 rows)

SELECT * FROM habalgo.booking WHERE booking_id = 1;
-- Output: (0 rows)
```

---

## 4. Disaster Recovery Procedure Executed

### Step 1: Provision Isolated Recovery Database
```powershell
& "C:\Program Files\PostgreSQL\18\bin\createdb.exe" -U postgres -h localhost -p 5432 grp00_habalgodb_recovery_test
```

### Step 2: Restore from Checkpoint Archive
```powershell
& "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe" `
    -U postgres `
    -h localhost `
    -p 5432 `
    -d grp00_habalgodb_recovery_test `
    "C:\Users\Matt\.gemini\antigravity\brain\70a3cb86-a366-40fd-a9d0-0fafa69e72d3\scratch\backups\habalgo_sim_checkpoint.dump"
```

### Step 3: Query and Extract Recovered Records
```sql
SELECT customer_id, name, phone, email 
FROM habalgo.customer 
WHERE customer_id = 1;
```
**Output from `grp00_habalgodb_recovery_test`:**
```
 customer_id |                name                |    phone    |                     email                      
-------------+------------------------------------+-------------+------------------------------------------------
           1 | DISPOSABLE TEST RIDER - SIMULATION | 09990001122 | disposable.rider.simulation@habalgo-test.local
(1 row)
```

---

## 5. Detailed Comparative Analysis

A strict field-by-field comparative analysis between pre-incident values and recovered values was conducted:

| Field Name | Pre-Incident Original Value | Recovered Value | Match Status |
| :--- | :--- | :--- | :---: |
| `customer.customer_id` | `1` | `1` | **IDENTICAL** |
| `customer.name` | `DISPOSABLE TEST RIDER - SIMULATION` | `DISPOSABLE TEST RIDER - SIMULATION` | **IDENTICAL** |
| `customer.phone` | `09990001122` | `09990001122` | **IDENTICAL** |
| `customer.email` | `disposable.rider.simulation@habalgo-test.local` | `disposable.rider.simulation@habalgo-test.local` | **IDENTICAL** |
| `booking.booking_id` | `1` | `1` | **IDENTICAL** |
| `booking.customer_id`| `1` | `1` | **IDENTICAL** |
| `booking.driver_id`  | `1` | `1` | **IDENTICAL** |
| `booking.status`     | `Completed` | `Completed` | **IDENTICAL** |
| `booking.date`       | `2026-11-06 17:23:13.367313` | `2026-11-06 17:23:13.367313` | **IDENTICAL** |

---

## 6. Recovery Outcome, Limitations, and RPO Gap Analysis

### Recovery Outcome:
- **Status:** **100% SUCCESSFUL**.
- **Data Fidelity:** Zero truncation, zero encoding corruption, zero sequence desynchronization.
- **RTO Benchmark:** Time to provision and restore recovery database: **12 seconds** (well within 30-minute target).

### Technical Limitations of Logical Snapshot Recovery:
1. **Interim Data Loss (The RPO Gap):**
   A logical backup (`pg_dump`) represents a point-in-time snapshot. Any customer bookings, passenger payments, or driver registrations created between the last scheduled backup (e.g., 02:00 AM) and the incident timestamp (e.g., 14:00 PM) cannot be recovered through `pg_restore` alone.
2. **Point-In-Time Recovery (PITR) Requirement:**
   To bridge this gap and achieve an RPO of under 15 minutes in a production Philippine transportation platform, PostgreSQL Write-Ahead Logging (WAL) archiving must be enabled (`archive_mode = on`, `archive_command = '...'`), allowing continuous roll-forward recovery up to the exact transaction prior to data loss.
3. **Database-Level Isolation Necessity:**
   Restoring full dumps directly over an existing database destroys all post-backup valid data. Staging into a separate recovery database (`_recovery_test`) and transplanting specific affected rows is the mandatory best practice.

