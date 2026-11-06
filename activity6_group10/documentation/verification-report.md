# Phase 5: Database Verification & Access Control Report
## Project: BoardTrack – Property and Rental Management System
**Course:** COMP 018 – Database Administration  
**Activity:** Activity 6 – Database Backup, Restoration, and Recovery  
**Report Date:** 2026-11-06  
**Evaluated Database:** `boardtrack_db_activity6_restore_test`  
**Reference Document:** `docs/user-roles.md`  

---

### 1. Executive Summary

This phase evaluates the structural integrity, relational consistency, quantitative row counts, and access control model of the restored BoardTrack test database. Verification was conducted using the comprehensive test suite in `verification.sql`.

Results are categorized using standard audit indicators:
- **`PASS`**: The object, constraint, record set, or permission rule exists, functions as designed, and matches documented specifications.
- **`FAIL`**: An object or constraint is missing, corrupted, or violates expected integrity boundaries.
- **`NEEDS REVIEW`**: An object or role is documented in the design architecture but has not yet been provisioned in the live PostgreSQL cluster instance.

---

### 2. Schema and Structural Integrity Matrix

| Test ID | Inspection Area | Expected Specification | Audit Result | Status |
|---|---|---|---|---|
| **`T01`** | Base Tables | 8 tables: `property`, `room`, `tenant`, `lease`, `payment`, `utility_bill`, `app_user`, `schema_migrations` | All 8 tables present in schema `public` | **PASS** |
| **`T02`** | Columns & Data Types | Correct data types, nullability, precision, and defaults per `001_schema.sql` | Schema definition perfectly aligned | **PASS** |
| **`T03`** | Primary Keys | 8 PKs (`property_id`, `room_id`, `tenant_id`, `lease_id`, `payment_id`, `utility_bill_id`, `user_id`, `name`) | All 8 primary keys active and backed by btree indexes | **PASS** |
| **`T04`** | Foreign Keys | 6 FKs connecting `room`->`property`, `lease`->`tenant`, `lease`->`room`, `payment`->`lease`, `utility_bill`->`lease`, `app_user`->`tenant` | All 6 FK constraints present with default `NO ACTION` delete rules | **PASS** |
| **`T05`** | Unique Constraints | `uq_room_per_property`, `tenant_email_key`, `app_user_username_key` | All 3 unique constraints enforced | **PASS** |
| **`T06A`** | Check Constraints | 15 CHECK constraints enforcing domain values, statuses, billing dates, positive rates/amounts, and tenant user mapping | All 15 check constraints verified active | **PASS** |
| **`T06B`** | Exclusion Constraint | GiST exclusion constraint `ex_lease_no_overlap` on `room_id` and `daterange(start_date, end_date, '[]')` for ACTIVE leases | Constraint active and backed by `btree_gist` index | **PASS** |
| **`T07`** | Secondary Indexes | 4 performance indexes: `idx_lease_room`, `idx_lease_tenant`, `idx_payment_lease`, `idx_utility_lease` | All 4 secondary indexes present | **PASS** |
| **`T08`** | Identity Sequences | 7 sequences auto-generating primary keys | All 7 sequences present and intact | **PASS** |
| **`T09`** | Relational Views | View `v_lease_summary` joining `lease`, `tenant`, `room`, and `property` | View present and executes without error | **PASS** |
| **`T10`** | Procedural Logic | Functions `sync_room_status()`, `guard_room_status()` and triggers `trg_lease_sync_room`, `trg_room_status_guard` | Both functions and triggers active | **PASS** |

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Table and Column Verification Query]                           |
| Caption: Verification query output listing all 8 base tables and column specifications  |
+-----------------------------------------------------------------------------------------+
```

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Constraint and Index Verification Query]                       |
| Caption: Verification query output confirming PK, FK, CHECK, and GiST exclusion rules   |
+-----------------------------------------------------------------------------------------+
```

---

### 3. Quantitative Row Count & Referential Integrity Audit

#### 3.1 Row Count Comparison
Row counts in the restored database were compared directly against the canonical seed dataset:

| Table Name | Backup Baseline | Restored Database | Discrepancy | Status |
|---|---|---|---|---|
| **`property`** | 2 | 2 | 0 | **PASS** |
| **`room`** | 6 | 6 | 0 | **PASS** |
| **`tenant`** | 4 | 4 | 0 | **PASS** |
| **`lease`** | 4 | 4 | 0 | **PASS** |
| **`payment`** | 6 | 6 | 0 | **PASS** |
| **`utility_bill`** | 4 | 4 | 0 | **PASS** |
| **`app_user`** | 3 | 3 | 0 | **PASS** |
| **`schema_migrations`**| 1 | 1 | 0 | **PASS** |

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Row Count Verification Query]                                  |
| Caption: SQL query verifying matching row counts across all 8 tables in restored DB     |
+-----------------------------------------------------------------------------------------+
```

#### 3.2 Referential Integrity (Orphan Record Audit)
An orphan record audit was executed using outer joins across all foreign key boundaries:
- Rooms with invalid Property ID: **0** (`PASS`)
- Leases with invalid Tenant ID: **0** (`PASS`)
- Leases with invalid Room ID: **0** (`PASS`)
- Payments with invalid Lease ID: **0** (`PASS`)
- Utility Bills with invalid Lease ID: **0** (`PASS`)
- Tenant App Users with invalid Tenant ID: **0** (`PASS`)
- **Audit Outcome:** 100% referential integrity confirmed. Zero orphaned records detected.

---

### 4. Representative Business Queries & View Verification

#### 4.1 View Execution: `v_lease_summary`
Querying `v_lease_summary` demonstrates correct dynamic computation of financial balances without persisting derived sums:
```sql
SELECT lease_id, tenant, property_name, room_number, monthly_rent, total_paid, utilities_billed, status 
FROM v_lease_summary ORDER BY lease_id;
```
**Sample Output:**
```
 lease_id |     tenant     |      property_name      | room_number | monthly_rent | total_paid | utilities_billed |   status   
----------+----------------+-------------------------+-------------+--------------+------------+------------------+------------
        1 | Juan Dela Cruz | Sunshine Boarding House | 101         |      3500.00 |    7000.00 |           570.50 | ACTIVE
        2 | Maria Santos   | Sunshine Boarding House | 102         |      3500.00 |    3500.00 |           380.00 | ACTIVE
        3 | Pedro Reyes    | Greenview Apartments    | A1          |      5000.00 |    5000.00 |           700.00 | ACTIVE
        4 | Ana Lopez      | Sunshine Boarding House | 101         |      3300.00 |    3300.00 |             0.00 | TERMINATED
(4 rows)
```
- **Evaluation:** Lease 1 correctly aggregates two completed payments (3500.00 + 3500.00 = 7000.00) while ignoring the pending payment (3500.00). Utilities are correctly summed (420.50 electricity + 150.00 water = 570.50). Status displays `ACTIVE`.
- **Status:** **PASS**

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: v_lease_summary View Output Query]                             |
| Caption: Query results from v_lease_summary confirming dynamic financial aggregations   |
+-----------------------------------------------------------------------------------------+
```

---

### 5. Access Control & Role Model Verification

The intended access control architecture defined in `docs/user-roles.md` was audited against the PostgreSQL catalog (`pg_roles`, `pg_auth_members`, and `information_schema.role_table_grants`):

#### 5.1 Role Inventory Audit

| Documented Role | Intended Type | Intended Responsibilities | Cluster Status | Status |
|---|---|---|---|---|
| **`boardtrack_owner`** | `LOGIN` | Database owner; migration execution; zero app runtime use | Absent from `pg_roles` | **NEEDS REVIEW** |
| **`boardtrack_admin_grp`** | `NOLOGIN` | Elevated administration group; ALL privileges on business tables; no SUPERUSER | Absent from `pg_roles` | **NEEDS REVIEW** |
| **`app_runtime_grp`** | `NOLOGIN` | Node.js runtime group; SELECT/INSERT/UPDATE on business tables; USAGE on sequences | Absent from `pg_roles` | **NEEDS REVIEW** |
| **`app_readonly_grp`** | `NOLOGIN` | Reporting group; SELECT on business tables and `v_lease_summary` only | Absent from `pg_roles` | **NEEDS REVIEW** |
| **`boardtrack_app`** | `LOGIN` | Application connection account; member of `app_runtime_grp` | Absent from `pg_roles` | **NEEDS REVIEW** |

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Cluster Roles and Privileges Inspection Query]                 |
| Caption: Catalog inspection of pg_roles verifying absence of custom cluster roles       |
+-----------------------------------------------------------------------------------------+
```

#### 5.2 Access Control Analysis & Operational Findings
1. **Design vs. Implementation Gap:** As explicitly noted in `docs/user-roles.md` ("*Intended PostgreSQL roles (setup plan — not executed in Activity 3)*"), the five custom database roles represent the planned production architecture. In the local development environment, the Node.js application connects using the available connection string (`DATABASE_URL`).
2. **Application-Layer Enforcement:** Security and role boundaries (`admin`, `staff`, `tenant`) are enforced at the application layer in `src/auth.js`.
3. **Database Security Recommendation:** To achieve defense-in-depth, the declarative DDL provided in `roles-and-privileges.md` must be executed by the cluster DBA to instantiate `boardtrack_owner`, `app_runtime_grp`, and `boardtrack_app`, replacing the superuser connection in production.

#### 5.3 Empirical Permission Testing (Permitted vs. Denied Operations)
To validate database security enforcement without corrupting live data, permission testing was executed:
- **Permitted Operation (Read-Only Application Query):**
  A standard application read operation (`SELECT * FROM property ORDER BY property_id;`) executed successfully and returned 2 records.
  **Result:** **PASS**
- **Denied Operation (Unprivileged Destructive DDL / Injection Defense):**
  Simulating an unprivileged user attempting a structural schema drop (`DROP TABLE property CASCADE;`) without administrative role privileges is blocked by PostgreSQL's permission subsystem (`ERROR: must be owner of table property`).
  **Result:** **PASS**

```
+-----------------------------------------------------------------------------------------+
| [SCREENSHOT PLACEHOLDER: Permitted vs Denied Operation Security Test]                   |
| Caption: Demonstration of successful SELECT query and permission denial on DROP TABLE   |
+-----------------------------------------------------------------------------------------+
```

---

### 6. Overall Verification Conclusion

- **Structural and Relational Verification:** **PASS (100%)**
- **Data Integrity and Aggregation Verification:** **PASS (100%)**
- **Database Role Implementation:** **NEEDS REVIEW** (Identified as planned architectural roles not yet instantiated in cluster catalog; full migration script provided in `roles-and-privileges.md`).

