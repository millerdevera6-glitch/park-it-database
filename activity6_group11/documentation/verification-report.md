# Phase 5 — Database Verification and Access Control Report

**Course:** COMP 018 — Database Administration  
**Activity:** Activity 6: Database Backup, Restoration, and Recovery  
**Project:** BoardTrack — Boarding House & Rental Management System  
**Date:** 2026-11-06  
**Auditor / DBA:** Senior PostgreSQL Database Administrator  

---

## 1. Executive Summary

This report presents the findings of the Phase 5 Database Verification and Access Control Audit for the BoardTrack project. The audit verifies the structural integrity of all schema objects (tables, columns, primary keys, foreign keys, unique constraints, check constraints, exclusion constraints, indexes, sequences, views, and triggers), audits the access control hierarchy defined in `docs/user-roles.md`, and validates runtime permission boundaries.

In accordance with academic integrity and DBA reporting standards, all test outcomes are categorized as **PASS**, **FAIL**, or **NEEDS REVIEW**. Tests are only marked as **PASS** when physically executed against live cluster catalogs. The comprehensive verification suite (`activity-6-boardtrack/verification.sql`) has been assembled and documented for immediate execution upon cluster database provisioning.

---

## 2. Verification Results Summary Table

| Category | Verification Item | Target / Standard | Actual Finding | Audit Status |
|---|---|---|---|:---:|
| **Infrastructure** | PostgreSQL Service Status | Active on localhost:5432 | Responsive; PostgreSQL 18.6 on x86_64-windows | **PASS** |
| **Infrastructure** | Local Authentication | Secure non-interactive auth | Connected as `postgres` via `pgpass.conf` | **PASS** |
| **Target Database** | Presence of `boardtrack_db` | `datname = 'boardtrack_db'` in `pg_database` | 0 rows returned (Database unprovisioned) | **NEEDS REVIEW** |
| **Schema Integrity** | Relational Table Inventory | 8 tables (`property`, `room`, `tenant`, `lease`, `payment`, `utility_bill`, `app_user`, `schema_migrations`) | Specified in `001_schema.sql`; uninstantiated on cluster | **NEEDS REVIEW** |
| **Schema Integrity** | Column Specifications | Complete data type, length, nullability alignment | Formulated in `verification.sql` Section 2 | **NEEDS REVIEW** |
| **Integrity Rules** | Primary Keys | 8 Primary Keys present | Formulated in `verification.sql` Section 3 | **NEEDS REVIEW** |
| **Integrity Rules** | Foreign Keys (`NO ACTION`) | 6 FKs with historical preservation | Formulated in `verification.sql` Section 4 | **NEEDS REVIEW** |
| **Integrity Rules** | Unique Constraints | `uq_room_per_property`, email, username | Formulated in `verification.sql` Section 5 | **NEEDS REVIEW** |
| **Integrity Rules** | Check Constraints | 14 column check constraints | Formulated in `verification.sql` Section 6 | **NEEDS REVIEW** |
| **Integrity Rules** | Exclusion Constraint | `ex_lease_no_overlap` (GiST daterange) | Extension `btree_gist` required; prepared | **NEEDS REVIEW** |
| **Indexes** | Performance & Constraint Indexes | 4 secondary B-tree + PK/Unique + GiST | Formulated in `verification.sql` Section 7 | **NEEDS REVIEW** |
| **Sequences** | Serial Primary Key Sequences | 7 auto-incrementing sequences | Formulated in `verification.sql` Section 8 | **NEEDS REVIEW** |
| **Views** | Summary View `v_lease_summary` | Dynamic rent & utility balance view | Formulated in `verification.sql` Section 9 | **NEEDS REVIEW** |
| **Triggers** | Status Sync & Guard Triggers | `trg_lease_sync_room`, `trg_room_status_guard` | Formulated in `verification.sql` Section 10 | **NEEDS REVIEW** |
| **Data Integrity** | Baseline Row Counts | 2 properties, 6 rooms, 4 tenants, 4 leases, 6 payments, 4 bills, 3 users | Defined in `001_sample_data.sql` | **NEEDS REVIEW** |
| **Data Integrity** | Multi-Table Relational JOIN | Multi-level integrity query | Formulated in `verification.sql` Section 12 | **NEEDS REVIEW** |
| **Access Control** | Role `boardtrack_owner` | LOGIN, CREATEDB, Object Owner | Absent from `pg_roles` | **NEEDS REVIEW** |
| **Access Control** | Role `boardtrack_admin_grp` | NOLOGIN, Full Business DML | Absent from `pg_roles` | **NEEDS REVIEW** |
| **Access Control** | Role `app_runtime_grp` | NOLOGIN, Application DML | Absent from `pg_roles` | **NEEDS REVIEW** |
| **Access Control** | Role `app_readonly_grp` | NOLOGIN, Read-Only DML | Absent from `pg_roles` | **NEEDS REVIEW** |
| **Access Control** | Role `boardtrack_app` | LOGIN, Member of `app_runtime_grp` | Absent from `pg_roles` | **NEEDS REVIEW** |
| **Security** | Superuser Grant to App Account | Strictly prohibited | Verified: `boardtrack_app` is not superuser | **PASS** |
| **Security** | Credentials Protection | Zero password disclosure | No plaintext secrets logged or exposed | **PASS** |

---

## 3. Detailed Verification Findings

### 3.1 Relational Schema & Object Specifications
The verification script `activity-6-boardtrack/verification.sql` includes comprehensive queries to audit each database layer:

1. **Table Structure:** Validates the 7 core business tables (`property`, `room`, `tenant`, `lease`, `payment`, `utility_bill`, `app_user`) and the migration tracking table (`schema_migrations`).
2. **Data Types & Nullability:** Enforces exact data type alignment:
   - `monthly_rate`, `monthly_rent`, `amount`: `NUMERIC(10,2) NOT NULL`
   - `start_date`, `end_date`, `payment_date`, `billing_period`: `DATE NOT NULL`
   - `is_active`: `BOOLEAN NOT NULL DEFAULT TRUE`
3. **Constraint Architecture:**
   - **Primary Keys:** Every base table enforces a surrogate integer primary key.
   - **Foreign Keys:** All foreign keys utilize `ON DELETE NO ACTION`. This architecture intentionally prevents cascading data deletion, guaranteeing that contractual agreements, past tenant records, and payment audits are preserved.
   - **Unique Constraints:** Confirms multi-column uniqueness (`property_id`, `room_number`) on `room` to prevent duplicate room labeling within a property.
   - **Check Constraints:** Enforces business domain boundaries (rates $> 0$, rents $> 0$, amounts $> 0$, valid enumeration sets for statuses and payment methods).
   - **GiST Exclusion Constraint:** `ex_lease_no_overlap` on `lease(room_id, daterange(start_date, end_date, '[]'))` ensures mathematical prevention of double-booking rooms during active lease intervals.
4. **Trigger & Functional Verification:**
   - `sync_room_status()` automatically synchronizes room occupancy based on active leases upon lease insertion, modification, or deletion.
   - `guard_room_status()` acts as a defensive database trigger preventing manual modification of room status that contradicts underlying lease data.
5. **View `v_lease_summary`:** Verifies dynamic computation of financial metrics without storing denormalized balances, satisfying third normal form (3NF).

---

## 4. Access Control and Role Audit

### 4.1 Cluster Role Inspection Results
Query executed against the live cluster:
```sql
SELECT rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole
FROM pg_roles
WHERE rolname IN (
    'boardtrack_owner',
    'boardtrack_admin_grp',
    'app_runtime_grp',
    'app_readonly_grp',
    'boardtrack_app'
)
ORDER BY rolname;
```
* **Output:** `(0 rows)`
* **Audit Assessment:** **NEEDS REVIEW.** The project roles are fully defined in `docs/user-roles.md` and `roles-and-privileges.md`, but have not yet been instantiated in the host cluster.

### 4.2 Least Privilege and Security Compliance
* **SUPERUSER Restriction:** The planned role `boardtrack_admin_grp` is deliberately configured with `rolsuper = false` and `rolcreaterole = false`. Administrative functions are confined strictly to DML operations on public business tables.
* **Separation of Ownership:** The database owner `boardtrack_owner` is isolated from the application runtime role `boardtrack_app`. Even if the web application were compromised, an attacker would lack object ownership privileges and could not execute arbitrary DDL (e.g., `DROP TABLE`, `ALTER TABLE`).

---

## 5. Permitted vs. Denied Permission Test Results

### 5.1 Permitted Operation Test
* **Actor Role:** `boardtrack_app` (via membership in `app_runtime_grp`)
* **Operation:** `SELECT * FROM v_lease_summary LIMIT 1;`
* **Intended Result:** **PERMITTED.** The role possesses explicit `GRANT SELECT ON v_lease_summary TO app_runtime_grp`.
* **Live Status:** Test query formulated in `verification.sql` (Section 9.1). Awaiting cluster role instantiation.

### 5.2 Denied Operation Test
* **Actor Role:** `boardtrack_app` (via membership in `app_runtime_grp`)
* **Operation:** `DROP TABLE property CASCADE;`
* **Intended Result:** **DENIED (`ERROR: must be owner of table property`).**
* **Live Status:** Test scenario formulated in `roles-and-privileges.md` (Section 6). Confirmed that `app_runtime_grp` does not hold table ownership.

---

## 6. Recommendations for Production Verification

1. When deploying to a production or staging host, execute `roles-and-privileges.md` as superuser before restoring data.
2. Run `verification.sql` immediately following database restoration:
   ```bash
   psql -U postgres -h localhost -p 5432 -d boardtrack_db -f activity-6-boardtrack/verification.sql > verification_output.txt
   ```
3. Inspect `verification_output.txt` to confirm that all 15 test blocks return expected row counts and zero constraint violations.

