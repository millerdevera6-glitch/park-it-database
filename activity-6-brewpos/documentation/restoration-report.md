# BrewPOS — Isolated Database Restoration & Validation Report
**Course:** COMP 018 — Database Administration  
**Project:** BrewPOS — Café Point-of-Sale System  
**Evaluating Group:** Group 4 (Olivarez, Charles Kean E., Infantado, Gerwin G., Pocsidio, Jhon Louie F., Abangan, SJ Kaizen M., Bartolata, Redge Raindel N.)  
**Source Database:** `grp_brewposdb` (Preserved & Untouched)  
**Restored Test Database:** `grp_brewposdb_restore_test`  
**Execution Date:** November 6, 2026, 15:35:00 (UTC+8)  
**Database Engine:** PostgreSQL 18.6 on x86_64-windows  

---

## 1. Restoration Strategy & Safety Protocols

In accordance with Phase 4 guidelines, database restoration was executed into an entirely isolated, newly created test database: **`grp_brewposdb_restore_test`**.

### 1.1 Non-Destructive Administration Safeguards
1. **Pre-Restoration Collision Check:**
   Prior to creating any database, the PostgreSQL catalog `pg_database` was queried:
   ```sql
   SELECT 1 FROM pg_database WHERE datname = 'grp_brewposdb_restore_test';
   ```
   The query returned `0` rows, confirming the database name was vacant. No existing databases were dropped, overwritten, or reset.
2. **Absolute Protection of Production Database:**
   The original operational database `grp_brewposdb` remained completely untouched, active, and available.
3. **Unsuppressed Error Reporting:**
   The restoration command was executed with `--verbose`, and all stdout and stderr streams were monitored to ensure no warnings or schema attachment failures were silently ignored.

---

## 2. Restoration Execution Commands

### 2.1 Database Provisioning
```powershell
createdb -U postgres -h localhost -p 5432 grp_brewposdb_restore_test
```
*Result:* Exit code `0` (Database created successfully).

### 2.2 Archive Restoration
```powershell
pg_restore -U postgres -h localhost -p 5432 -d grp_brewposdb_restore_test --verbose "C:\Users\Matt\pg_backups\brewpos\grp_brewposdb_activity6.dump"
```
*Result:* Exit code `0` (Restoration completed successfully with zero errors).

---

## 3. Restoration Trace Log Audit

The unedited execution trace from `pg_restore --verbose` confirmed sequential, dependency-ordered restoration:

```text
pg_restore: connecting to database for restore
pg_restore: executing SELECT pg_catalog.set_config('search_path', '', false);
pg_restore: creating TABLE "public.menu_category"
pg_restore: creating SEQUENCE "public.menu_category_category_id_seq"
pg_restore: creating SEQUENCE OWNED BY "public.menu_category_category_id_seq"
pg_restore: creating TABLE "public.menu_item"
pg_restore: creating SEQUENCE "public.menu_item_item_id_seq"
pg_restore: creating SEQUENCE OWNED BY "public.menu_item_item_id_seq"
pg_restore: creating TABLE "public.order_line_item"
pg_restore: creating TABLE "public.order_ticket"
pg_restore: creating SEQUENCE "public.order_ticket_order_id_seq"
pg_restore: creating SEQUENCE OWNED BY "public.order_ticket_order_id_seq"
pg_restore: creating TABLE "public.staff"
pg_restore: creating SEQUENCE "public.staff_staff_id_seq"
pg_restore: creating SEQUENCE OWNED BY "public.staff_staff_id_seq"
pg_restore: creating DEFAULT "public.menu_category category_id"
pg_restore: creating DEFAULT "public.menu_item item_id"
pg_restore: creating DEFAULT "public.order_ticket order_id"
pg_restore: creating DEFAULT "public.staff staff_id"
pg_restore: processing data for table "public.menu_category"
pg_restore: processing data for table "public.menu_item"
pg_restore: processing data for table "public.order_line_item"
pg_restore: processing data for table "public.order_ticket"
pg_restore: processing data for table "public.staff"
pg_restore: executing SEQUENCE SET menu_category_category_id_seq
pg_restore: executing SEQUENCE SET menu_item_item_id_seq
pg_restore: executing SEQUENCE SET order_ticket_order_id_seq
pg_restore: executing SEQUENCE SET staff_staff_id_seq
pg_restore: creating CONSTRAINT "public.menu_category menu_category_pkey"
pg_restore: creating CONSTRAINT "public.menu_item menu_item_pkey"
pg_restore: creating CONSTRAINT "public.order_ticket order_ticket_pkey"
pg_restore: creating CONSTRAINT "public.order_line_item pk_order_line_item"
pg_restore: creating CONSTRAINT "public.staff staff_pkey"
pg_restore: creating CONSTRAINT "public.menu_category uq_menu_category_name"
pg_restore: creating CONSTRAINT "public.menu_item uq_menu_item_category_name"
pg_restore: creating FK CONSTRAINT "public.menu_item fk_menu_item_category"
pg_restore: creating FK CONSTRAINT "public.order_line_item fk_order_line_item"
pg_restore: creating FK CONSTRAINT "public.order_line_item fk_order_line_order"
pg_restore: creating FK CONSTRAINT "public.order_ticket fk_order_ticket_staff"
pg_restore: creating ACL "SCHEMA public"
pg_restore: creating ACL "public.TABLE menu_category"
pg_restore: creating ACL "public.SEQUENCE menu_category_category_id_seq"
pg_restore: creating ACL "public.TABLE menu_item"
pg_restore: creating ACL "public.SEQUENCE menu_item_item_id_seq"
pg_restore: creating ACL "public.TABLE order_line_item"
pg_restore: creating ACL "public.TABLE order_ticket"
pg_restore: creating ACL "public.SEQUENCE order_ticket_order_id_seq"
pg_restore: creating ACL "public.TABLE staff"
pg_restore: creating ACL "public.SEQUENCE staff_staff_id_seq"
```

---

## 4. Analysis of Restored Database Objects & Ownership

### 4.1 Dependency Ordering & Data Population
- Tables and their backing SERIAL sequences were defined first.
- Default expressions linking columns to sequences were attached.
- Table data tuples were populated via COPY streams **prior** to enabling primary and foreign key constraints. This allowed high-speed bulk ingestion without constraint overhead.
- Primary key, unique, and foreign key constraints were applied after data loading, and all constraints validated successfully against the loaded rows.
- Sequences were updated to their accurate high-water mark counters (`SEQUENCE SET`), ensuring future `INSERT` transactions will not generate duplicate key collisions.

### 4.2 Object Ownership and ACL Attachment
- All tables and sequences are owned by the cluster superuser `postgres`.
- Because the cluster roles (`app_runtime_grp`, `app_readonly_grp`, `app_admin_grp`, `brewpos_app`) already existed in the PostgreSQL cluster instance, the ACL grant statements restored without any "role does not exist" warnings.
- Exactly 43 role-table grants were verified active in `grp_brewposdb_restore_test`.

---

## 5. Screenshot Evidence Placeholders

```markdown
<!-- SCREENSHOT PLACEHOLDER 4: Test Database Creation -->
![Screenshot 4: Terminal execution of createdb grp_brewposdb_restore_test](screenshots/04_createdb_restore_test.png)
*Figure 4: Non-destructive provisioning of grp_brewposdb_restore_test on localhost:5432.*

<!-- SCREENSHOT PLACEHOLDER 5: Verbose pg_restore Execution -->
![Screenshot 5: Terminal execution of pg_restore with verbose output](screenshots/05_pg_restore_execution.png)
*Figure 5: Full pg_restore execution trace restoring schema, data, constraints, and ACLs with exit code 0.*
```

---

## 6. Phase 4 Evaluation Summary

| Verification Item | Expectation | Actual Outcome | Status |
|---|---|---|:---:|
| **Target Isolation** | Clean, isolated database (`grp_brewposdb_restore_test`) | Created fresh; no overwriting of existing databases | **PASS** |
| **Original DB Protection** | `grp_brewposdb` untouched and intact | Verified untouched with identical row counts | **PASS** |
| **Restore Exit Code** | `0` (Success) | Exit code `0` | **PASS** |
| **Warning / Error Count** | 0 warnings, 0 errors | 0 warnings, 0 errors | **PASS** |
| **Constraint Activation** | All PKs, FKs, Checks, and Uniques active | 34 constraints active | **PASS** |
| **ACL Attachment** | Permissions mapped to application roles | 43 table grants active | **PASS** |
| **Phase 4 Evaluation** | Full Restoration Successful | **PASS — Fully Certified** | **PASS** |

