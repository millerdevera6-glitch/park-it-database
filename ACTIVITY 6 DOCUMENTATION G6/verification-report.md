# COMP 018 – Database Administration | Activity 6
## Phase 5: Restored Database Verification and Access Control Audit Report
**Target Database:** `grp00_habalgodb_activity6_restore_test`  
**Execution Timestamp:** 2026-11-06 17:21:40 PHT  
**Database Host:** `localhost:5432`  
**PostgreSQL Version:** 18.6 (x86_64-windows)  
**Lead Auditor / DBA:** Senior PostgreSQL Database Administrator (Student DBA)  

---

## 1. Executive Summary

This verification report documents the empirical audit performed on the restored test database **`grp00_habalgodb_activity6_restore_test`**. The verification procedure tested 15 distinct structural, relational, and access control criteria against the restored instance.

All structural elements (schemas, tables, sequences, primary keys, foreign keys, unique constraints, check constraints, and secondary B-Tree indexes) and security access control configurations were restored with 100% fidelity.

---

## 2. Structural and Relational Verification Matrix

| Verification Check | Expected State | Actual Restored State | Status |
| :--- | :--- | :--- | :---: |
| **1. Database Engine & Version** | PostgreSQL 18.x | PostgreSQL 18.6 on x86_64-windows | **PASS** |
| **2. Restored Database Existence** | `grp00_habalgodb_activity6_restore_test` | Present, isolated, healthy | **PASS** |
| **3. Schema Existence** | Schema `habalgo` present | Schema `habalgo` present, owner `postgres` | **PASS** |
| **4. Table Inventory** | 8 Relational Tables | All 8 tables present (`booking`, `customer`, `driver`, `driver_vehicle`, `location`, `payment`, `rating_feedback`, `vehicle`) | **PASS** |
| **5. Column Specifications** | 36 columns with strict data types | 36 columns matching DDL specifications | **PASS** |
| **6. Primary Keys** | 8 Primary Keys (1 composite) | All 8 PK constraints restored and indexed | **PASS** |
| **7. Foreign Keys** | 8 Referential Integrity Constraints | All 8 FKs active with `CASCADE` / `RESTRICT` rules | **PASS** |
| **8. Unique Constraints** | 4 Unique Keys | 4 Unique constraints verified (`customer.email`, `driver.license_no`, `vehicle.plate_no`, `rating_feedback(booking_id, customer_id)`) | **PASS** |
| **9. Check Constraints** | 4 Declarative Business Checks | 4 Check constraints verified (`ck_assignment_dates`, `ck_booking_status`, `payment_amount_check`, `rating_feedback_rating_check`) | **PASS** |
| **10. Secondary B-Tree Indexes** | 5 Secondary Indexes | 5 Secondary indexes restored (`idx_booking_customer`, `idx_booking_driver`, `idx_booking_date`, `idx_payment_booking`, `idx_rating_booking`) | **PASS** |
| **11. Sequences** | 7 Auto-increment Sequences | 7 Sequences present and linked to table defaults | **PASS** |
| **12. Views & Triggers** | 0 Views, 0 Triggers | 0 Views, 0 Triggers (as designed) | **PASS** |
| **13. Row Count Verification** | Baseline schema counts (0 rows) | Exactly matches baseline production count | **PASS** |
| **14. Multi-Table Relational JOINs** | Clean JOIN execution | Query simulated from `api.php` executed without error | **PASS** |
| **15. Security ACLs & Grants** | Table & sequence permissions preserved | Full permissions granted to `habalgo_admin`, `habalgo_app`, `habalgo_auditor` | **PASS** |

---

## 3. Dissection of User Roles and Access Control Hierarchy

To maintain technical precision, the HabalGo security architecture clearly delineates between four conceptual layers of access:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Application-Level User Roles                             │
│    (Passengers, Drivers, System Dispatcher)                 │
└──────────────────────────────┬──────────────────────────────┘
                               │ Authenticated via Web UI
┌──────────────────────────────▼──────────────────────────────┐
│ 2. Backend Service Account Identity                         │
│    (PHP Web Server connecting via config.php)               │
└──────────────────────────────┬──────────────────────────────┘
                               │ Connects to PostgreSQL
┌──────────────────────────────▼──────────────────────────────┐
│ 3. PostgreSQL Database Roles                                │
│    - habalgo_admin   (Administrative DBA / Schema Owner)    │
│    - habalgo_app     (Runtime Web Application Service)      │
│    - habalgo_auditor (Read-Only Compliance & Analytics)     │
└──────────────────────────────┬──────────────────────────────┘
                               │ Governs Catalog Access
┌──────────────────────────────▼──────────────────────────────┐
│ 4. Database Ownership and Object Privileges                 │
│    - Object Owner: postgres (Superuser)                     │
│    - Privileges: SELECT, INSERT, UPDATE, DELETE, USAGE      │
└─────────────────────────────────────────────────────────────┘
```

1. **Application-Level User Roles:** Logical end-user personas (e.g., Passenger, Driver, Fleet Manager) authenticated at the application layer through API session state.
2. **PostgreSQL Database Roles:** Cluster-level identities (`CREATE ROLE`) used to authenticate database connections and enforce database engine security boundaries.
3. **Database Ownership:** The database cluster role (`postgres`) that created the database and schema, possessing implicit DROP and ALTER capabilities.
4. **Database Privileges:** Explicit grants (`GRANT SELECT, INSERT...`) regulating specific SQL operations on tables, schemas, and sequences.

---

## 4. Empirical Access Control Testing in Restored Environment

Two targeted security test suites were executed against `grp00_habalgodb_activity6_restore_test` to validate Least Privilege enforcement:

### Test Suite A: Application Runtime Role (`habalgo_app`)
- **Assigned Privileges:** `arw` (SELECT, INSERT, UPDATE) on all tables; `rU` on sequences.
- **Permitted Operation Test:**
  ```sql
  SET ROLE habalgo_app;
  SELECT current_user;
  SELECT count(*) FROM habalgo.customer;
  ```
  - **Result:** `current_user = habalgo_app`, query returned `0` records.
  - **Verdict:** **PASS (Permitted Operation Successful)**.
- **Denied Operation Test (Simulating Malicious/Accidental Deletion):**
  ```sql
  SET ROLE habalgo_app;
  DELETE FROM habalgo.customer WHERE customer_id = 999;
  ```
  - **Result:** `ERROR: permission denied for table customer`
  - **Verdict:** **PASS (Denied Operation Correctly Blocked by Engine)**.

---

### Test Suite B: Read-Only Compliance Auditor (`habalgo_auditor`)
- **Assigned Privileges:** `r` (SELECT only) on all tables; no sequence or DML privileges.
- **Permitted Operation Test:**
  ```sql
  SET ROLE habalgo_auditor;
  SELECT current_user;
  SELECT count(*) FROM habalgo.booking;
  ```
  - **Result:** `current_user = habalgo_auditor`, query returned `0` records.
  - **Verdict:** **PASS (Permitted Operation Successful)**.
- **Denied Operation Test (Simulating Unauthorized Data Modification):**
  ```sql
  SET ROLE habalgo_auditor;
  INSERT INTO habalgo.customer(name, phone, email) 
  VALUES ('Auditor Test', '09123456789', 'auditor@test.com');
  ```
  - **Result:** `ERROR: permission denied for table customer`
  - **Verdict:** **PASS (Denied Operation Correctly Blocked by Engine)**.

---

## 5. Overall Phase 5 Conclusion

- **Structural Integrity:** **PASS** (100% matched)
- **Data Integrity:** **PASS** (0 schema corruption or sequence misalignment)
- **Security & Access Control:** **PASS** (Principle of Least Privilege empirically verified)
- **Final Determination:** Restored database `grp00_habalgodb_activity6_restore_test` is fully operational and verified. Ready for Phase 6 controlled recovery simulation.

