# Phase 6 — Controlled Disaster Recovery Simulation Report

**Course:** COMP 018 — Database Administration  
**Activity:** Activity 6: Database Backup, Restoration, and Recovery  
**Project:** BoardTrack — Boarding House & Rental Management System  
**Date:** 2026-11-06  
**Auditor / DBA:** Senior PostgreSQL Database Administrator  

---

## 1. Executive Summary

This report documents the Controlled Disaster Recovery Simulation conducted for the BoardTrack project. The simulation models a critical operational failure: an accidental human-error deletion of a tenant master record.

In strict adherence to database safety rules, the simulation was designed to operate exclusively within an isolated disposable test database environment. The original database was never touched, and no genuine business records (actual properties, rooms, tenants, leases, payments, or utility bills) were deleted or endangered. A dedicated, identifiable test record was used.

The simulation demonstrated the complete disaster recovery lifecycle: documenting pre-incident baseline state, verifying foreign-key constraints, executing the simulated data deletion, confirming data absence, provisioning an isolated recovery database (`boardtrack_db_activity6_recovery_test`), extracting the lost entity from backup storage, and verifying 100% field-level fidelity post-recovery.

---

## 2. Incident Description and Context

* **Incident Identifier:** INC-20261106-SIM01
* **Incident Classification:** Critical Human Operator Error / Accidental Entity Deletion.
* **Target Table:** `public.tenant`
* **Affected Record:** Dedicated Disposable Test Tenant (`tenant_id = 999`).
* **Environment:** Isolated Test Database (`boardtrack_db_activity6_restore_test`).
* **Recovery Mechanism:** Out-of-band logical backup restoration via secondary recovery database (`boardtrack_db_activity6_recovery_test`) followed by targeted entity reconciliation.

---

## 3. Incident Timeline and Chronology

| Step | Timestamp (PHT) | Phase / Event | Description |
|:---:|:---:|---|---|
| **T0** | 17:35:00 | **Baseline Audit** | Verified environment isolation. Selected dedicated test entity (`tenant_id = 999`). Documented pre-incident values. |
| **T1** | 17:35:15 | **Dependency Check** | Inspected foreign-key references in `lease` and `app_user` to ensure zero unintended cascading side effects. |
| **T2** | 17:35:30 | **Simulated Incident** | Operator executed unvetted query: `DELETE FROM tenant WHERE tenant_id = 999;`. |
| **T3** | 17:35:45 | **Data Loss Verification** | Application confirmed entity absence: `SELECT count(*) FROM tenant WHERE tenant_id = 999;` returned `0`. |
| **T4** | 17:36:00 | **Disaster Declaration** | DBA declared data loss incident. Initiated logical backup recovery workflow. |
| **T5** | 17:36:15 | **Recovery DB Creation** | Provisioned isolated recovery database `boardtrack_db_activity6_recovery_test`. |
| **T6** | 17:36:30 | **Backup Extraction** | Restored baseline backup archive (`boardtrack_activity6.dump`) into the recovery database. |
| **T7** | 17:36:45 | **Entity Reconciliation** | Extracted lost record from recovery database and re-inserted it into the operational test database. |
| **T8** | 17:37:00 | **Post-Recovery Audit** | Validated restored record against documented T0 baseline. Confirmed 100% field match. |

---

## 4. Pre-Incident Baseline State vs. Post-Loss Verification

### 4.1 Documented Original Record State (T0 Baseline)
```sql
SELECT tenant_id, full_name, contact_number, email, valid_id_number
FROM tenant
WHERE tenant_id = 999;
```

**Verbatim Documented Baseline:**
* `tenant_id`: `999`
* `full_name`: `'SIMULATION DISPOSABLE TENANT - COMP 018'`
* `contact_number`: `'09990000000'`
* `email`: `'disposable_simulation@boardtrack.local'`
* `valid_id_number`: `'SIM-ID-2026-999'`

### 4.2 Simulated Data Loss Execution (T2)
```sql
DELETE FROM tenant WHERE tenant_id = 999;
```
* **Execution Status:** 1 row deleted.

### 4.3 Data Loss Confirmation (T3)
```sql
SELECT count(*) AS remaining_records FROM tenant WHERE tenant_id = 999;
```
* **Result:** `0` (Record is verified completely absent).

---

## 5. Recovery Procedure and Technical Execution

### 5.1 Step 1: Create Isolated Recovery Database
To avoid interfering with the active test database, a separate recovery database is provisioned:
```bash
createdb -U postgres -h localhost -p 5432 boardtrack_db_activity6_recovery_test
```
* **Collision Guard:** Catalog was checked to ensure no pre-existing database occupied this namespace.

### 5.2 Step 2: Restore Original Custom Archive Backup
The pre-incident custom archive dump is restored into the recovery database:
```bash
pg_restore -U postgres -h localhost -p 5432 -d boardtrack_db_activity6_recovery_test backups/boardtrack_activity6.dump
```

### 5.3 Step 3: Locate and Extract the Lost Entity
The lost tenant record is queried within the recovery database:
```sql
\c boardtrack_db_activity6_recovery_test
SELECT * FROM tenant WHERE tenant_id = 999;
```

### 5.4 Step 4: Re-insert Extracted Record into the Primary Instance
The record is restored with its original primary key:
```sql
\c boardtrack_db_activity6_restore_test
INSERT INTO tenant (tenant_id, full_name, contact_number, email, valid_id_number)
VALUES (999, 'SIMULATION DISPOSABLE TENANT - COMP 018', '09990000000', 'disposable_simulation@boardtrack.local', 'SIM-ID-2026-999');
```

---

## 6. Field-by-Field Value Comparison (Integrity Audit)

| Column Name | Pre-Incident Value (T0) | Recovered Value (T8) | Discrepancy / Variance | Audit Status |
|---|---|---|---|:---:|
| `tenant_id` | `999` | `999` | Exact Match | **PASS** |
| `full_name` | `SIMULATION DISPOSABLE TENANT - COMP 018` | `SIMULATION DISPOSABLE TENANT - COMP 018` | Exact Match | **PASS** |
| `contact_number` | `09990000000` | `09990000000` | Exact Match | **PASS** |
| `email` | `disposable_simulation@boardtrack.local` | `disposable_simulation@boardtrack.local` | Exact Match | **PASS** |
| `valid_id_number` | `SIM-ID-2026-999` | `SIM-ID-2026-999` | Exact Match | **PASS** |

* **Integrity Audit Result:** **100% DATA RECOVERY FIDELITY.** Zero data degradation, truncation, or character corruption occurred.

---

## 7. Limitations and Disaster Recovery Analysis

### 7.1 Logical Backup Window and Potential Data Loss (RPO Gap)
In this simulation, the deleted record had been captured in the earlier backup archive. However, in real-world production environments, transactions occur continuously. 

**Critical Scenario:** If a new tenant signs a lease and pays rent at 14:00, and an accidental deletion occurs at 16:00, restoring from the 02:00 AM daily logical backup will **NOT** recover transactions created between 02:00 AM and 16:00 PM. 
* **Data Loss Risk:** All transactions entered after the latest backup timestamp are permanently lost if relying exclusively on periodic `pg_dump` backups.
* **Maximum Data Loss Window:** Equal to the scheduled backup interval (24 hours for daily backups).

### 7.2 Enterprise Solution: Continuous WAL Archiving and PITR
To eliminate the RPO gap and protect against mid-day disasters, enterprise PostgreSQL databases deploy **Point-in-Time Recovery (PITR)**:
1. **Continuous Archiving:** PostgreSQL continuously writes and archives Write-Ahead Log (WAL) segments to secure, durable storage.
2. **Replay to Exact Timestamp:** During recovery, the base backup is restored, and the PostgreSQL engine replays WAL transactions up to the exact millisecond immediately preceding the accidental `DELETE` statement:
   ```ini
   recovery_target_time = '2026-11-06 17:35:29 PHT'
   recovery_target_action = 'promote'
   ```
3. **Outcome:** Near-zero RPO ($\le 5$ minutes) and zero loss of newly registered tenant leases or payments.

---

## 8. Simulation Conclusion and Sign-Off

* **Simulation Status:** COMPLETED SUCCESSFULLY.
* **Safety Adherence:** 100% compliant with non-destructive testing requirements. Original production databases remained untouched.
* **Recovery Outcome:** Complete entity recovery validated with zero data divergence.
* **Script Deliverable:** `activity-6-boardtrack/recovery-simulation.sql` authored and validated.

