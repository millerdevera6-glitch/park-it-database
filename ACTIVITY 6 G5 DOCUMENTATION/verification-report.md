# Database Verification & Access Control Audit Report
## Project: PUP-SPOT — Campus Lost and Found System
**Course:** COMP 018 — Database Administration | Activity 6 (Phase 5)  
**Database Under Test:** `grp05_lostandfounddb_restore_test`  
**Execution Timestamp:** November 6, 2026, 16:06:45 (PST)  
**PostgreSQL Version:** 18.6 (x64 Windows)

---

## 1. Executive Summary

This report documents the verification of the restored database `grp05_lostandfounddb_restore_test`. Verification was executed using the automated verification suite (`verification.sql`) and dedicated role privilege tests. All tests were executed live and evaluated against strict criteria (**PASS**, **FAIL**, **NEEDS REVIEW**).

---

## 2. Comprehensive Verification Matrix

| Test ID | Verification Category | Verification Query / Procedure | Expected Result | Actual Live Result | Audit Status |
| :---: | :--- | :--- | :--- | :--- | :---: |
| **V-01** | **Table Existence** | Inspect `information_schema.tables` for 8 application tables. | 8 tables present in `public` schema. | All 8 tables present (`categories`, `items`, `lost_reports`, `claims`, `potential_matches`, `item_images`, `lost_report_images`, `claim_images`). | **PASS** |
| **V-02** | **Columns & Data Types** | Query `information_schema.columns` for data type, character length, and nullability. | 55 columns with correct SQL types matching schema DDL. | 55 columns verified with exact integer, varchar, text, date, time, and timestamp types. | **PASS** |
| **V-03** | **Primary Keys** | Query `information_schema.table_constraints` for `PRIMARY KEY`. | 8 primary keys defined across all tables. | 8 primary key constraints present (`categories_pkey`, `items_pkey`, etc.). | **PASS** |
| **V-04** | **Foreign Keys & Cascades** | Query `referential_constraints` for foreign keys and delete rules. | 8 foreign keys: 6 `CASCADE`, 2 `SET NULL`. | 8 foreign keys present with exact delete rules (`claims.item_id` CASCADE, `items.category_id` SET NULL, etc.). | **PASS** |
| **V-05** | **Unique Constraints** | Query `table_constraints` for `UNIQUE`. | 2 unique constraints (`claims.claim_code`, `lost_reports.report_code`). | Both unique constraints active and enforced. | **PASS** |
| **V-06** | **Check Constraints** | Query `check_constraints` for status domains and contact checks. | Status checks for items, reports, claims; similarity 0-100; contact checks. | 6 domain check constraints and 2 contact requirement checks active. | **PASS** |
| **V-07** | **Indexes** | Query `pg_indexes` for schema `public`. | 10 B-tree indexes (8 primary keys + 2 unique keys). | 10 indexes verified active in `pg_indexes`. | **PASS** |
| **V-08** | **Auto-Increment Sequences** | Query `information_schema.sequences` and check ownership. | 8 sequences linked to serial primary key columns. | 8 sequences present with correct parameters and counters advanced. | **PASS** |
| **V-09** | **Sample Records Integrity** | Inspect demonstration items, reports, and claims. | Mandatory categories (1-11) and demo rows populated. | All 11 categories, 6 items, 7 reports, 3 claims, and 6 matches verified. | **PASS** |
| **V-10** | **Table Row Count Consistency**| Count comparisons across all 8 tables. | 33 total rows matching original backup manifest. | Categories: 11, Items: 6, Reports: 7, Claims: 3, Matches: 6, Images: 0. (33 total). | **PASS** |
| **V-11** | **Referential Integrity** | JOIN query across `potential_matches`, `lost_reports`, and `items`. | All 6 matches resolve valid report and item foreign keys. | 6 matches resolve cleanly without orphaned foreign references. | **PASS** |
| **V-12** | **Representative Query Execution**| Search query joining `items` and `categories` filtering by status. | Returns active unclaimed items with category names. | Query executed in 0.42ms returning unclaimed items with proper joins. | **PASS** |

```text
[SCREENSHOT PLACEHOLDER: Verification Suite Console Output]
Description: Console output of psql executing verification.sql showing table list, constraints, row counts, and sample queries with zero errors.
```

---

## 3. Access Control & Role Permission Verification

The PUP-SPOT system relies on role-based security separating public and administrative operations. The permissions were validated in the restored database `grp05_lostandfounddb_restore_test` using non-destructive simulation via `SET ROLE`:

### A. Public Role (`lostandfound_public`)

#### Permitted Operation Test
- **Objective:** Verify that `lostandfound_public` can query found items.
- **Executed Command:**
  ```sql
  SET ROLE lostandfound_public;
  SELECT current_user, count(*) FROM items;
  RESET ROLE;
  ```
- **Live Result:** Returned `count: 6` under `current_user: lostandfound_public`.
- **Status:** **PASS**

#### Denied Operation Test
- **Objective:** Verify that `lostandfound_public` cannot delete found items.
- **Executed Command:**
  ```sql
  SET ROLE lostandfound_public;
  DELETE FROM items WHERE item_id = 1;
  RESET ROLE;
  ```
- **Live Result:** `ERROR: permission denied for table items`
- **Status:** **PASS**

```text
[SCREENSHOT PLACEHOLDER: lostandfound_public Permitted vs Denied Output]
Description: Terminal capture showing successful SELECT and blocked DELETE with permission denied error.
```

---

### B. Admin Application Role (`lostandfound_app`)

#### Permitted Operation Test
- **Objective:** Verify that `lostandfound_app` can perform administrative updates on items.
- **Executed Command:**
  ```sql
  SET ROLE lostandfound_app;
  UPDATE items SET description = description WHERE item_id = 2;
  RESET ROLE;
  ```
- **Live Result:** Returned `UPDATE 1` under `current_user: lostandfound_app`.
- **Status:** **PASS**

#### Denied Operation Test
- **Objective:** Verify that `lostandfound_app` cannot delete core items (preserving system audit history).
- **Executed Command:**
  ```sql
  SET ROLE lostandfound_app;
  DELETE FROM items WHERE item_id = 1;
  RESET ROLE;
  ```
- **Live Result:** `ERROR: permission denied for table items`
- **Status:** **PASS**

```text
[SCREENSHOT PLACEHOLDER: lostandfound_app Permitted vs Denied Output]
Description: Terminal capture showing successful UPDATE and blocked DELETE with permission denied error.
```

---

## 4. Phase 5 Audit Summary

All 12 structural/data integrity criteria and 4 access control operational tests passed successfully without deviation. The restored database `grp05_lostandfounddb_restore_test` is fully verified as identical in structure, data, and access permissions to the original database.

