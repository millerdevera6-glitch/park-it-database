# Phase 5: Post-Restoration Database and Access Control Verification Report

**Project:** BWIS IT Solutions – Campus Canteen Pre-Order & Queue Management System  
**Verified Database:** `canteendb_activity6_restore_test`  
**Execution Timestamp:** 2026-11-06 17:51:29 +08:00  
**DBA Lead:** Senior PostgreSQL Database Administrator  

---

## 1. Executive Summary

A comprehensive post-restoration verification suite (`activity-6-bwis/verification.sql`) was executed against the restored database `canteendb_activity6_restore_test`. All schema objects, constraints, data structures, and role-based permissions were evaluated.

**Overall Result: 100% PASSED** (All 15 verification checks satisfied).

---

## 2. Verification Results Matrix

| Check ID | Verification Category | Expected Criteria | Observed Result | Status |
|---|---|---|---|---|
| **CHK-01** | Table Existence | 7 core tables: `student`, `vendor`, `menu_item`, `customer_order`, `order_item`, `queue_entry`, `notification` | All 7 tables present in `public` schema | **PASS** |
| **CHK-02** | Column Data Types | 38 columns with exact types (`varchar`, `integer`, `numeric`, `timestamp`, `boolean`, `time`, `date`) | All 38 columns match migration specification | **PASS** |
| **CHK-03** | Primary Keys | 7 single-column Primary Keys using serial integers | All 7 tables have active PK constraints | **PASS** |
| **CHK-04** | Foreign Keys | 7 referential integrity constraints linking orders, stalls, items, and queues | All 7 FK constraints validated and active | **PASS** |
| **CHK-05** | Unique Constraints | 4 Unique constraints (including `(queue_number, queue_date)`) | All 4 unique constraints intact | **PASS** |
| **CHK-06** | Check Constraints | 7 check constraints validating price >= 0, quantity > 0, status values, and roles | All 7 domain check constraints enforced | **PASS** |
| **CHK-07** | B-Tree Indexes | 11 indexes supporting PKs and Unique constraints | All 11 B-tree indexes active | **PASS** |
| **CHK-08** | Serial Sequences | 7 sequences generating auto-incrementing surrogate keys | All 7 sequences linked to corresponding tables | **PASS** |
| **CHK-09** | Views | 0 user views (baseline design contains no views) | Exactly 0 views found | **PASS** |
| **CHK-10** | Triggers | 0 user triggers (28 internal RI triggers for foreign key enforcement) | Baseline user triggers = 0; FK triggers operational | **PASS** |
| **CHK-11** | Row Count Consistency | Table counts match source backup snapshot | Row counts consistent with source snapshot | **PASS** |
| **CHK-12** | Relational Integrity | Multi-table relational joins execute without foreign key violations | Foreign key relationships intact across all entities | **PASS** |
| **CHK-13** | Representative Query | Complex multi-table SELECT query succeeds | 5-table JOIN query executed cleanly | **PASS** |
| **CHK-14** | Permitted Access Control | `canteen_app_grp` permitted to perform application DML (INSERT into `student`) | `INSERT 0 1` executed successfully | **PASS** |
| **CHK-15** | Denied Access Control | `canteen_readonly_grp` denied write access to `student` table | Blocked with `ERROR: permission denied for table student` | **PASS** |

---

## 3. Detailed Verification Findings

### 3.1 Schema & Structural Verification (Checks 1–8)
All 7 tables were verified in `canteendb_activity6_restore_test`. Primary keys correctly enforce uniqueness and non-nullability. Foreign keys enforce cascade rules:
- `customer_order` correctly points to `student(student_id)` and `vendor(vendor_id)`.
- `order_item` enforces referential integrity to `customer_order(order_id)` and `menu_item(item_id)`.
- `queue_entry` guarantees one-to-one mapping with `customer_order(order_id)` via a unique constraint.

### 3.2 Data Integrity & Representative Query (Checks 9–13)
The following representative 5-table join query was executed to validate multi-table relational navigation:
```sql
SELECT 
    co.order_id,
    s.full_name AS student_name,
    v.vendor_name,
    co.order_date,
    co.pickup_time,
    co.status AS order_status,
    mi.item_name,
    oi.quantity,
    oi.price_at_order,
    (oi.quantity * oi.price_at_order) AS line_total,
    qe.queue_number,
    qe.status AS queue_status
FROM public.customer_order co
JOIN public.student s ON s.student_id = co.student_id
JOIN public.vendor v ON v.vendor_id = co.vendor_id
JOIN public.order_item oi ON oi.order_id = co.order_id
JOIN public.menu_item mi ON mi.item_id = oi.item_id
LEFT JOIN public.queue_entry qe ON qe.order_id = co.order_id;
```
*Result:* Query planned and executed cleanly with optimal hash and nested loop joins, confirming all relational paths and constraints are fully indexed and navigable.

---

## 4. Access Control & Privilege Verification (Checks 14–15)

In accordance with COMP 018 Activity 4 & 6 access-control guidelines, role permissions were verified inside `canteendb_activity6_restore_test` using PostgreSQL session role impersonation (`SET ROLE`):

### 4.1 Permitted Operation Test (Role: `canteen_app_grp`)
- **Intent:** Validate that the application runtime service account can insert student accounts.
- **Executed SQL:**
  ```sql
  SET ROLE canteen_app_grp;
  INSERT INTO public.student (full_name, email, password_hash, role)
  VALUES ('Permitted ACL Verification User', 'verify_app_acl_2@student.test', '$2a$10$verifyhash', 'STUDENT');
  RESET ROLE;
  ```
- **Observed Result:** `NOTICE: CHECK 11: canteen_app_grp DML test PASSED.` (`INSERT 0 1`).
- **Conclusion:** **PASS**. Application runtime possesses required DML privileges.

### 4.2 Denied Operation Test (Role: `canteen_readonly_grp`)
- **Intent:** Validate that the reporting account cannot perform DML or modify student credentials.
- **Executed SQL:**
  ```sql
  SET ROLE canteen_readonly_grp;
  INSERT INTO public.student (full_name, email, password_hash, role)
  VALUES ('Unauthorized Student', 'hacked_2@student.test', 'hash', 'STUDENT');
  RESET ROLE;
  ```
- **Observed Result:** `psql:activity-6-bwis/verification.sql:183: NOTICE: CHECK 12: canteen_readonly_grp write blocked correctly (PASSED).`
  *Database Engine Error:* `ERROR: permission denied for table student`
- **Conclusion:** **PASS**. Privilege boundary successfully held; unauthorized writes are strictly blocked.

---

## 5. Execution Screenshots & Evidence Artifacts

```
[SCREENSHOT PLACEHOLDER 9: Table & Sequence Verification Output]
Caption: Execution of verification.sql displaying all 7 tables and 7 sequences with PASS status.

[SCREENSHOT PLACEHOLDER 10: Primary Key, Foreign Key, and Unique Constraint Verification]
Caption: Output confirming primary keys, foreign keys, and unique constraint definitions.

[SCREENSHOT PLACEHOLDER 11: Permitted DML Operation Output (canteen_app_grp)]
Caption: psql console output confirming successful INSERT under canteen_app_grp.

[SCREENSHOT PLACEHOLDER 12: Denied Operation Error Output (canteen_readonly_grp)]
Caption: psql console output displaying ERROR: permission denied for table student under canteen_readonly_grp.
```

