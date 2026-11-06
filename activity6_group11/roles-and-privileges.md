# PostgreSQL Roles, Privileges, and Access Control Architecture

**Course:** COMP 018 — Database Administration  
**Activity:** Activity 6: Database Backup, Restoration, and Recovery  
**Project:** BoardTrack — Boarding House & Rental Management System  
**Date:** 2026-11-06  
**Auditor / DBA:** Senior PostgreSQL Database Administrator  

---

## 1. Overview of the Access Control Architecture

The BoardTrack rental management system enforces a defense-in-depth security model separating **application authentication** (managed via session cookies, bcrypt password hashing, and the RBAC table in `src/auth.js`) from **database-tier authorization** (managed via PostgreSQL roles, schema permissions, and object grants).

The application server establishes connections to PostgreSQL using a single runtime service account (`boardtrack_app`). End users (landlords, caretakers, tenants) authenticate to the web application and are mapped to application roles; they never receive direct individual PostgreSQL database accounts.

---

## 2. Intended Role Hierarchy and Specifications (from `docs/user-roles.md`)

The database tier access model is structured into 5 distinct PostgreSQL roles:

```
                  +-----------------------------------+
                  |         boardtrack_owner          |
                  |  (LOGIN, CREATEDB, DB Owner)      |
                  +-----------------------------------+
                                    |
      +-----------------------------+-----------------------------+
      |                             |                             |
      v                             v                             v
+-----------------------+ +-----------------------+ +-----------------------+
|  boardtrack_admin_grp | |    app_runtime_grp    | |   app_readonly_grp    |
|   (NOLOGIN, All DML)  | |  (NOLOGIN, CRUD DML)  | |  (NOLOGIN, Read-Only) |
+-----------------------+ +-----------------------+ +-----------------------+
                                    ^
                                    | (IN ROLE)
                          +-----------------------+
                          |    boardtrack_app     |
                          |  (LOGIN, Web Runtime) |
                          +-----------------------+
```

### 2.1 Role Attribute and Purpose Matrix

| Role Name | Type | Login Allowed | Administrative Privileges | Intended Purpose |
|---|---|---|---|---|
| `boardtrack_owner` | User Role | **LOGIN** | `CREATEDB`, `NOSUPERUSER`, `NOCREATEROLE` | Master database owner and schema migration executor. Owns all tables, sequences, views, and functions. Not used by the web application. |
| `boardtrack_admin_grp` | Group Role | **NOLOGIN** | `NOSUPERUSER`, `NOCREATEDB`, `NOCREATEROLE` | Elevated administrative group representing the landlord/system admin. Grants full DML on all public business tables, but strictly no superuser rights. |
| `app_runtime_grp` | Group Role | **NOLOGIN** | `NOSUPERUSER`, `NOCREATEDB`, `NOCREATEROLE` | Operational runtime group for the Node.js application. Permits `SELECT`, `INSERT`, `UPDATE`, and `DELETE` on operational tables, `USAGE` on sequences, and `SELECT` on `v_lease_summary`. |
| `app_readonly_grp` | Group Role | **NOLOGIN** | `NOSUPERUSER`, `NOCREATEDB`, `NOCREATEROLE` | Read-only reporting and audit role. Has `SELECT` privilege on business tables and `v_lease_summary`. |
| `boardtrack_app` | User Role | **LOGIN** | `NOSUPERUSER`, `NOCREATEDB`, `NOCREATEROLE` | Web application login account. Inherits permissions through membership in `app_runtime_grp`. Password maintained securely outside version control. |

---

## 3. Database Object Privileges Matrix

### 3.1 Database and Schema Permissions

| Target Object | Privilege Type | `boardtrack_owner` | `boardtrack_admin_grp` | `app_runtime_grp` | `app_readonly_grp` |
|---|---|---|---|---|---|
| Database `boardtrack_db` | `CONNECT` | YES (Owner) | YES | YES | YES |
| Schema `public` | `USAGE` | YES (Owner) | YES | YES | YES |
| Schema `public` | `CREATE` | YES (Owner) | NO | NO | NO |

### 3.2 Relational Tables and View Permissions

| Object Name | Object Type | `boardtrack_admin_grp` | `app_runtime_grp` | `app_readonly_grp` |
|---|---|---|---|---|
| `property` | Base Table | `ALL` | `SELECT, INSERT, UPDATE, DELETE` | `SELECT` |
| `room` | Base Table | `ALL` | `SELECT, INSERT, UPDATE, DELETE` | `SELECT` |
| `tenant` | Base Table | `ALL` | `SELECT, INSERT, UPDATE, DELETE` | `SELECT` |
| `lease` | Base Table | `ALL` | `SELECT, INSERT, UPDATE, DELETE` | `SELECT` |
| `payment` | Base Table | `ALL` | `SELECT, INSERT, UPDATE, DELETE` | `SELECT` |
| `utility_bill` | Base Table | `ALL` | `SELECT, INSERT, UPDATE, DELETE` | `SELECT` |
| `app_user` | Base Table | `ALL` | `SELECT, INSERT, UPDATE, DELETE` | `NONE` (Credentials protected) |
| `v_lease_summary` | View | `SELECT` | `SELECT` | `SELECT` |
| `schema_migrations`| System Table| `ALL` | `SELECT` | `NONE` |

### 3.3 Sequence Permissions
All serial auto-incrementing sequences (`*_seq`) require `USAGE` permission for `INSERT` operations:
* `boardtrack_admin_grp`: `USAGE, SELECT, UPDATE` on all sequences.
* `app_runtime_grp`: `USAGE` on all sequences.
* `app_readonly_grp`: **NONE** (No sequence privileges required).

---

## 4. Live Cluster Role Audit Findings

An inspection of `pg_roles` was executed on the live PostgreSQL 18.6 cluster:

```sql
SELECT rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole
FROM pg_roles
WHERE rolname IN (
    'boardtrack_owner',
    'boardtrack_admin_grp',
    'app_runtime_grp',
    'app_readonly_grp',
    'boardtrack_app'
);
```

### 4.1 Audit Output
```
 rolname | rolcanlogin | rolsuper | rolcreatedb | rolcreaterole 
---------+-------------+----------+-------------+---------------
(0 rows)
```

### 4.2 Finding and Status
* **Audit Finding:** The 5 custom project roles defined in `docs/user-roles.md` have **not yet been instantiated** on the live cluster.
* **Cluster Superuser Present:** `postgres` (`rolsuper=t`, `rolcreatedb=t`, `rolcreaterole=t`).
* **Built-in System Roles Present:** Standard PostgreSQL 18 system roles (`pg_database_owner`, `pg_read_all_data`, `pg_write_all_data`, etc.).
* **Compliance Assessment:** Confirmed consistent with Phase 1 and Activity 5 audit findings. The project roles exist as an architectural design in `docs/user-roles.md` but were not created on the live host.

---

## 5. Formal Role and Privilege Provisioning DDL

To provision the access control architecture on any PostgreSQL instance prior to restoration, execute the following script as cluster superuser (`postgres`):

```sql
-- ============================================================================
-- BoardTrack Access Control Provisioning Script
-- ============================================================================

-- Step 1: Create Group Roles (NOLOGIN)
CREATE ROLE boardtrack_admin_grp NOLOGIN;
CREATE ROLE app_runtime_grp      NOLOGIN;
CREATE ROLE app_readonly_grp     NOLOGIN;

-- Step 2: Create User Roles (LOGIN)
-- Note: Replace '<SET_SECURE_PASSWORD>' with a strong cryptographically generated secret.
CREATE ROLE boardtrack_owner WITH LOGIN CREATEDB PASSWORD '<SET_OWNER_PASSWORD>';
CREATE ROLE boardtrack_app   WITH LOGIN PASSWORD '<SET_APP_PASSWORD>' IN ROLE app_runtime_grp;

-- Step 3: Database & Schema Grants
GRANT CONNECT ON DATABASE boardtrack_db TO boardtrack_admin_grp, app_runtime_grp, app_readonly_grp;
GRANT USAGE ON SCHEMA public TO boardtrack_admin_grp, app_runtime_grp, app_readonly_grp;

-- Step 4: Table Grants
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO boardtrack_admin_grp;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO boardtrack_admin_grp;

GRANT SELECT, INSERT, UPDATE, DELETE ON 
    property, room, tenant, lease, payment, utility_bill, app_user 
    TO app_runtime_grp;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_runtime_grp;
GRANT SELECT ON v_lease_summary TO app_runtime_grp;

GRANT SELECT ON property, room, tenant, lease, payment, utility_bill TO app_readonly_grp;
GRANT SELECT ON v_lease_summary TO app_readonly_grp;

-- Step 5: Default Privileges for Future Tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_runtime_grp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO app_runtime_grp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO app_readonly_grp;
```

---

## 6. Access Control Test Scenarios (Permitted vs. Denied Operations)

To validate the runtime permissions of `boardtrack_app` (via `app_runtime_grp`) and `app_readonly_grp`, two formal test cases are established:

### Test Case 1: Permitted Database Operation
* **Testing Role:** `boardtrack_app` (Member of `app_runtime_grp`)
* **Operation:** Querying aggregated lease metrics from `v_lease_summary`.
* **SQL:**
  ```sql
  SELECT lease_id, tenant, property_name, room_number, total_paid, utilities_billed
  FROM v_lease_summary
  LIMIT 5;
  ```
* **Expected Result:** **SUCCESS.** The role possesses explicit `GRANT SELECT ON v_lease_summary TO app_runtime_grp`.

### Test Case 2: Denied Database Operation
* **Testing Role:** `boardtrack_app` (Member of `app_runtime_grp`)
* **Operation:** Attempting an unauthorized administrative DDL operation (e.g., dropping a core business table).
* **SQL:**
  ```sql
  DROP TABLE property CASCADE;
  ```
* **Expected Result:** **DENIED (Permission Denied).**
  ```
  ERROR: must be owner of table property
  ```
  Even though `app_runtime_grp` has DML privileges (SELECT, INSERT, UPDATE, DELETE), it lacks table ownership (`ALTER/DROP` permissions), enforcing strict protection against destructive schema tampering.

### Test Case 3: Read-Only Denied Operation
* **Testing Role:** `app_readonly_grp`
* **Operation:** Attempting to delete a payment record.
* **SQL:**
  ```sql
  DELETE FROM payment WHERE payment_id = 1;
  ```
* **Expected Result:** **DENIED (Permission Denied).**
  ```
  ERROR: permission denied for table payment
  ```
  `app_readonly_grp` is granted only `SELECT`, preventing any data mutation.

