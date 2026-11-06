# Phase 6: Controlled Recovery Simulation Report

**Project:** BWIS IT Solutions – Campus Canteen Pre-Order & Queue Management System  
**Disaster Simulation Target DB:** `canteendb_activity6_restore_test` (Mutated disposable row only)  
**Recovery Target DB:** `canteendb_activity6_recovery_test` (Isolated fresh recovery target)  
**Production Database:** `canteendb` (100% Preserved & Untouched)  
**Execution Timestamp:** 2026-11-06 17:48:24 – 17:49:14 +08:00  
**DBA Lead:** Senior PostgreSQL Database Administrator  

---

## 1. Incident Overview and Scope

To simulate a realistic operational incident without risking real data, a controlled disaster recovery drill was executed. The simulation modeled an accidental administrative deletion of a canteen vendor stall (`vendor` table) containing active menu and profile associations.

### Safety Guarantee
In strict compliance with database administration safety standards:
- **Zero Genuine Records Altered:** No real customer accounts, vendor stalls, pre-orders, or queue entries were touched.
- **Strictly Disposable Test Data:** A unique, clearly tagged disposable test entity was created exclusively within the restored test environment.
- **Production Isolation:** The original database (`canteendb`) was never connected to or modified during the drill.

---

## 2. Incident Timeline

| Time Marker | Action Description | Environment | Executed Command / Query | Recorded Output / Checksum |
|---|---|---|---|---|
| **T0 (17:46:37)** | Initial Baseline Full Backup | `canteendb` | `pg_dump -Fc -f bwis_activity6.dump` | 25,798 bytes, SHA-256: `8C89EE1569E2...` |
| **T1 (17:47:16)** | Initial Restore Test Database | `canteendb_activity6_restore_test` | `pg_restore -d canteendb_activity6_restore_test` | Complete schema and ACL restoration |
| **T2 (17:48:24)** | Disposable Marker Provisioning | `canteendb_activity6_restore_test` | `INSERT INTO vendor (vendor_name, email, ...)` | `vendor_id: 1`, `email: disposable_vendor@recovery.test` |
| **T3 (17:48:30)** | Before-State Cryptographic Fingerprinting | `canteendb_activity6_restore_test` | JSON extraction & SHA-256 calculation | **SHA-256:** `af2e58b68913bff0c4ac7a24dd1e700d7b62f218b1cea3d6f4b468883e0a02aa` |
| **T4 (17:48:37)** | Point-in-Time Safeguard Snapshot | External Storage | `pg_dump -Fc -f bwis_recovery_snapshot.dump` | Snapshot archive capturing T2 marker state |
| **T5 (17:48:44)** | **Simulated Incident: Accidental DELETE** | `canteendb_activity6_restore_test` | `DELETE FROM vendor WHERE email = '...'` | `DELETE 1` (Stall accidentally dropped) |
| **T6 (17:48:46)** | Data Loss Verification | `canteendb_activity6_restore_test` | `SELECT count(*) WHERE email = '...'` | `remaining_count: 0` (Confirmed missing) |
| **T7 (17:48:50)** | Recovery Target Database Provisioning | Cluster Catalog | `createdb canteendb_activity6_recovery_test` | Fresh isolated recovery database created |
| **T8 (17:48:56)** | Disaster Recovery Restoration | `canteendb_activity6_recovery_test` | `pg_restore -d canteendb_activity6_recovery_test` | Complete archive restored (Exit Code: 0) |
| **T9 (17:49:04)** | Recovered Entity Extraction | `canteendb_activity6_recovery_test` | JSON query for deleted vendor record | Row found: `{"vendor_id":1,"vendor_name":...}` |
| **T10 (17:49:12)**| Post-Recovery Cryptographic Verification | Analysis Engine | SHA-256 comparison between T3 and T9 | **SHA-256:** `af2e58b68913bff0c4ac7a24dd1e700d7b62f218b1cea3d6f4b468883e0a02aa` |

---

## 3. Cryptographic Verification & Comparison Results

### Before-State JSON (Recorded at T3):
```json
{"vendor_id":1,"vendor_name":"RECOVERY_TEST_DISPOSABLE_STALL","contact_number":"09123456789","email":"disposable_vendor@recovery.test","is_active":true}
```
- **Before-State SHA-256:** `af2e58b68913bff0c4ac7a24dd1e700d7b62f218b1cea3d6f4b468883e0a02aa`

### Recovered-State JSON (Extracted from Recovery DB at T9):
```json
{"vendor_id":1,"vendor_name":"RECOVERY_TEST_DISPOSABLE_STALL","contact_number":"09123456789","email":"disposable_vendor@recovery.test","is_active":true}
```
- **Recovered-State SHA-256:** `af2e58b68913bff0c4ac7a24dd1e700d7b62f218b1cea3d6f4b468883e0a02aa`

### Verdict:
**100% BIT-FOR-BIT EXACT MATCH.**  
Every column value, data type, and boolean flag matched the recorded pre-incident state without truncation, character conversion error, or sequence discrepancy.

---

## 4. Recovery Point Objective (RPO) & Data Loss Analysis

The drill provided critical DBA insights regarding data loss windows:

1. **Recovery from Latest Snapshot (T4):**
   - Zero data loss occurred because the backup captured the database state immediately prior to the accidental deletion.
2. **Recovery from Prior Off-Peak Backup (T0):**
   - Had recovery been performed using only the baseline daily backup (`bwis_activity6.dump`), the disposable marker record would **not** have been recovered, because it was created after T0.
   - **RPO Implication:** Relying solely on once-daily logical backups creates an RPO gap of up to **24 hours**. In a live campus canteen processing hundreds of student orders each lunch period, up to a full day of pre-orders and transaction logs would be permanently lost if a disaster occurred at 17:00 PM.
   - **DBA Recommendation:** Production deployments must implement **continuous PostgreSQL WAL archiving** (`archive_mode = on`, `archive_command = 'cp %p /wal_archive/%f'`) paired with regular base backups. This enables Point-In-Time Recovery (PITR) to any arbitrary transaction timestamp, reducing actual RPO to under 5 minutes.

---

## 5. Execution Screenshots & Evidence Artifacts

```
[SCREENSHOT PLACEHOLDER 13: Disposable Marker Row Insertion and JSON Extraction]
Caption: Execution of INSERT query creating RECOVERY_TEST_DISPOSABLE_STALL and row_to_json output.

[SCREENSHOT PLACEHOLDER 14: Accidental Deletion and Absence Verification]
Caption: Output of DELETE FROM vendor returning DELETE 1 and subsequent count(*) returning 0.

[SCREENSHOT PLACEHOLDER 15: Fresh Recovery Database Creation and Restoration]
Caption: Execution of createdb canteendb_activity6_recovery_test followed by pg_restore.

[SCREENSHOT PLACEHOLDER 16: Recovered Row Verification and SHA-256 Match]
Caption: PowerShell verification confirming identical SHA-256 hashes (af2e58b68913...).
```

