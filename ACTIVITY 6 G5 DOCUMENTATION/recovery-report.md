# Controlled Recovery Simulation & Disaster Recovery Report
## Project: PUP-SPOT — Campus Lost and Found System
**Course:** COMP 018 — Database Administration | Activity 6 (Phase 6)  
**Primary Sandbox Target:** `grp05_lostandfounddb_restore_test`  
**Disaster Recovery Database:** `grp05_lostandfounddb_recovery_test`  
**Execution Timestamp:** November 6, 2026, 16:07:49 (PST)  
**PostgreSQL Version:** 18.6 (x64 Windows)

---

## 1. Executive Summary

This report documents the execution of **Phase 6: Controlled Recovery Simulation**. The objective was to simulate accidental data deletion within an isolated database environment, evaluate data absence, provision a dedicated recovery database (`grp05_lostandfounddb_recovery_test`), restore the verified backup archive, extract the lost record, compare recovered values against pre-incident benchmarks, and restore service without modifying the original production database (`grp05_lostandfounddb`).

---

## 2. Safety Precautions & Disposable Target Selection

To adhere to safety guidelines:
1. **Original Database Isolation:** `grp05_lostandfounddb` was never accessed or modified.
2. **Preservation of Genuine Application Data:** No genuine lost reports, found items, claim requests, or student accounts were targeted.
3. **Foreign Key Dependency Analysis:** The disposable record was selected from `potential_matches` (`match_id = 5`). This table contains computed similarity metrics with no inbound foreign key references, guaranteeing that deletion would not trigger unintended cascading side-effects.

---

## 3. Incident Timeline

| Step / Timestamp | Phase / Action | Description | Environment |
| :---: | :--- | :--- | :--- |
| **T0 (16:07:40)** | **Pre-Incident State Recorded** | Inspected `potential_matches` record with `match_id = 5` and logged all column values. | `grp05_lostandfounddb_restore_test` |
| **T1 (16:07:49)** | **Simulated Accidental Deletion** | Executed `DELETE FROM potential_matches WHERE match_id = 5;`. | `grp05_lostandfounddb_restore_test` |
| **T2 (16:07:55)** | **Incident Verification** | Queried table; confirmed count dropped from 6 to 5 and query for `match_id = 5` returned 0 rows. | `grp05_lostandfounddb_restore_test` |
| **T3 (16:08:06)** | **Recovery DB Provisioning** | Created separate recovery database `grp05_lostandfounddb_recovery_test` using `createdb`. | PostgreSQL Cluster |
| **T4 (16:08:37)** | **Backup Restoration** | Restored `grp05_lostandfounddb_activity6.dump` into `grp05_lostandfounddb_recovery_test` via `pg_restore`. | `grp05_lostandfounddb_recovery_test` |
| **T5 (16:08:50)** | **Record Extraction & Validation** | Located `match_id = 5` in recovery database; extracted and compared against pre-incident baseline. | `grp05_lostandfounddb_recovery_test` |
| **T6 (16:09:05)** | **Surgical Restoration** | Re-inserted the extracted record into `grp05_lostandfounddb_restore_test`. | `grp05_lostandfounddb_restore_test` |
| **T7 (16:09:12)** | **Production Safety Audit** | Verified that production database `grp05_lostandfounddb` remained untouched with all 6 rows intact. | `grp05_lostandfounddb` |

---

## 4. Pre-Incident vs Recovered Record Comparison

The pre-incident values recorded at T0 were compared with the record extracted from the recovery database at T5:

```sql
SELECT match_id, report_id, item_id, similarity_score, created_at 
FROM potential_matches 
WHERE match_id = 5;
```

### Detailed Field Comparison Matrix

| Column Name | Pre-Incident Benchmark (T0) | Recovered Value (T5) | Post-Restore Value (T6) | Match Status |
| :--- | :--- | :--- | :--- | :---: |
| `match_id` | `5` | `5` | `5` | **IDENTICAL** |
| `report_id` | `1` | `1` | `1` | **IDENTICAL** |
| `item_id` | `5` | `5` | `5` | **IDENTICAL** |
| `similarity_score` | `61.25` | `61.25` | `61.25` | **IDENTICAL** |
| `created_at` | `2026-11-05 16:08:51.39409` | `2026-11-05 16:08:51.39409` | `2026-11-05 16:08:51.39409` | **IDENTICAL** |

```text
[SCREENSHOT PLACEHOLDER: Incident Deletion & Absence Verification]
Description: Terminal capture showing DELETE 1 command, count decreasing from 6 to 5, and match_id=5 returning 0 rows.
```

```text
[SCREENSHOT PLACEHOLDER: Recovery Database Query and Surgical Re-Insertion]
Description: Terminal capture showing match_id=5 located in grp05_lostandfounddb_recovery_test and re-inserted into restore_test.
```

---

## 5. Recovery Outcome & Methodology Evaluation

### Chosen Recovery Methodology: Surgical Recovery via Staging Instance
Rather than executing a destructive cluster-wide restore over the active database (which would discard any valid transactions that occurred between the backup and the incident), the recovery employed **Staging-Instance Surgical Recovery**:
1. Restore the dump to an isolated staging recovery database (`grp05_lostandfounddb_recovery_test`).
2. Query and extract solely the affected records.
3. Surgically re-insert the missing data into the active database (`grp05_lostandfounddb_restore_test`).
4. Re-verify relational integrity and application availability.

### Recovery Outcome
- **Data Recovery Rate:** **100%** of the deleted record was recovered with zero column divergence.
- **Downtime / Service Interruption:** Zero downtime for unaffected records.
- **Production Impact:** Zero impact on `grp05_lostandfounddb`.

---

## 6. Critical Analysis: Limitations and Potential Data Loss Scenarios

While this simulation demonstrated recovery of data existing within the backup archive, a DBA must evaluate real-world edge cases:

### 1. The Point-in-Time Data Loss Gap (RPO Limit)
- **Scenario:** If a student submits a new lost report or staff logs a newly found item at 10:00 AM, and an accidental deletion occurs at 11:00 AM, but the latest logical backup was taken at 02:00 AM:
- **Impact:** Any record inserted or modified between 02:00 AM and the incident time **cannot be recovered from the logical backup alone**.
- **Data Loss Window:** Up to 24 hours under a daily logical backup schedule (RPO = 24h).

### 2. Mitigation via Continuous WAL Archiving & Point-In-Time Recovery (PITR)
To overcome the limitations of daily logical backups:
- **Continuous Write-Ahead Logging (WAL):** Enable `wal_level = replica` and `archive_mode = on` with an automated `archive_command` pushing closed WAL segments (16MB chunks) to enterprise storage.
- **PITR Capability:** With base backups plus WAL replay, the DBA can recover the cluster to the exact second (`recovery_target_time = '2026-11-06 10:59:58'`) immediately preceding the errant `DELETE` or `DROP TABLE` statement, reducing potential data loss to under 5 minutes.

