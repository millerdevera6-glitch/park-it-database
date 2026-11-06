# HabalGo Roles, Privileges, and Access Control Architecture
## COMP 018 – Database Administration | Activity 6
**System:** HabalGo – Ride & Booking Management System  
**Database:** `grp00_habalgodb` (Restored: `grp00_habalgodb_activity6_restore_test`)  
**Schema:** `habalgo`  
**Document Author:** Senior PostgreSQL Database Administrator (Student DBA)  

---

## 1. Multi-Tier Security and Role Hierarchy

In the HabalGo ecosystem, security and access control are structured across four clearly separated architectural domains:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Application-Level User Personas                          │
│    - Passenger (Ride Booking, Payment, Feedback)            │
│    - Driver (Vehicle Assignment, Ride Status Acceptance)    │
│    - Dispatcher / Administrator (System Management)         │
└──────────────────────────────┬──────────────────────────────┘
                               │ Authenticated via Web UI
┌──────────────────────────────▼──────────────────────────────┐
│ 2. Backend Application Connection Context                   │
│    - PHP PDO Service Layer (config.php, api.php)            │
│    - Prepared Parameterized SQL Queries                     │
└──────────────────────────────┬──────────────────────────────┘
                               │ Authenticates to Database
┌──────────────────────────────▼──────────────────────────────┐
│ 3. PostgreSQL Database Roles (Cluster Level)                │
│    - habalgo_admin    (Full schema & object management)     │
│    - habalgo_app      (Runtime DML: SELECT, INSERT, UPDATE) │
│    - habalgo_auditor  (Read-Only compliance: SELECT only)   │
└──────────────────────────────┬──────────────────────────────┘
                               │ Enforces Object Permissions
┌──────────────────────────────▼──────────────────────────────┐
│ 4. Relational Object Privileges                             │
│    - Schema USAGE                                           │
│    - Table SELECT, INSERT, UPDATE, DELETE                   │
│    - Sequence USAGE, SELECT                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. PostgreSQL Roles vs. Application Roles

| Dimension | Application-Level Roles | PostgreSQL Database Roles |
| :--- | :--- | :--- |
| **Storage Context** | Application code / session tokens / UI state | PostgreSQL system catalog (`pg_authid`, `pg_roles`) |
| **Authentication** | Password hashes, phone OTP, API sessions | Database connection handshake (MD5 / SCRAM-SHA-256) |
| **Scope of Enforcement** | Web interface forms and endpoint routing | Database storage engine and SQL parser |
| **Example Personas** | Passenger, Driver, Fleet Dispatcher | `habalgo_admin`, `habalgo_app`, `habalgo_auditor` |
| **Privilege Granularity** | UI view visibility and button access | Table, column, sequence, and row-level security (RLS) |

---

## 3. Database Roles Specification and Privileges Matrix

### Role Definitions

| PostgreSQL Role | Type | Login Allowed? | Primary Responsibility |
| :--- | :--- | :---: | :--- |
| **`postgres`** | Superuser | Yes | Cluster administrator, global catalog maintenance |
| **`habalgo_admin`** | User / Admin | Yes | Application DBA, schema management, migration runner |
| **`habalgo_app`** | Service Account | Yes | Web application runtime connection (`api.php`) |
| **`habalgo_auditor`** | Analyst Account | Yes | Read-only compliance auditor, BI reporting |
| **`app_runtime_grp`** | Group Role | No | NOLOGIN permission template for application runtime |
| **`app_readonly_grp`** | Group Role | No | NOLOGIN permission template for read-only auditors |

### Object Privilege Matrix (`habalgo` Schema)

| Object Name | Type | `habalgo_admin` | `habalgo_app` | `habalgo_auditor` |
| :--- | :--- | :---: | :---: | :---: |
| **Schema `habalgo`** | Schema | `USAGE, CREATE` | `USAGE` | `USAGE` |
| **`customer`** | Table | `ALL` (`arwdDxtm`) | `SELECT, INSERT, UPDATE` | `SELECT` |
| **`driver`** | Table | `ALL` (`arwdDxtm`) | `SELECT, INSERT, UPDATE` | `SELECT` |
| **`vehicle`** | Table | `ALL` (`arwdDxtm`) | `SELECT, INSERT, UPDATE` | `SELECT` |
| **`driver_vehicle`** | Table | `ALL` (`arwdDxtm`) | `SELECT, INSERT, UPDATE` | `SELECT` |
| **`location`** | Table | `ALL` (`arwdDxtm`) | `SELECT, INSERT, UPDATE` | `SELECT` |
| **`booking`** | Table | `ALL` (`arwdDxtm`) | `SELECT, INSERT, UPDATE` | `SELECT` |
| **`payment`** | Table | `ALL` (`arwdDxtm`) | `SELECT, INSERT, UPDATE` | `SELECT` |
| **`rating_feedback`**| Table | `ALL` (`arwdDxtm`) | `SELECT, INSERT, UPDATE` | `SELECT` |
| **All Sequences (7)**| Sequence | `USAGE, SELECT, UPDATE` | `USAGE, SELECT` | `NONE` |

*Security Highlight: Notice that `habalgo_app` is purposefully denied `DELETE` and `TRUNCATE` privileges on all tables. This prevents destructive SQL injection or accidental data wiping from the web frontend.*

---

## 4. Role Recreation and Disaster Recovery Procedures

Because PostgreSQL roles are cluster-wide, restoring a single-database dump (`pg_restore`) does not recreate roles if recovering to a fresh or unprovisioned PostgreSQL cluster.

### Procedure for Fresh Cluster Deployment:

```sql
-- 1. Create Group Roles (Permission Bundles)
CREATE ROLE app_runtime_grp NOLOGIN;
CREATE ROLE app_readonly_grp NOLOGIN;

-- 2. Create Application Accounts
CREATE ROLE habalgo_admin LOGIN PASSWORD 'ChangeMeAdmin2026!';
CREATE ROLE habalgo_app LOGIN PASSWORD 'ChangeMeApp2026!';
CREATE ROLE habalgo_auditor LOGIN PASSWORD 'ChangeMeAuditor2026!';

-- 3. Assign Role Memberships
GRANT app_runtime_grp TO habalgo_app;
GRANT app_readonly_grp TO habalgo_auditor;

-- 4. Connect to Target Database
\connect grp00_habalgodb

-- 5. Grant Schema Usage
GRANT USAGE ON SCHEMA habalgo TO habalgo_admin, habalgo_app, habalgo_auditor;
GRANT CREATE ON SCHEMA habalgo TO habalgo_admin;

-- 6. Grant Table Privileges
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA habalgo TO habalgo_admin;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA habalgo TO habalgo_app;
GRANT SELECT ON ALL TABLES IN SCHEMA habalgo TO habalgo_auditor;

-- 7. Grant Sequence Privileges
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA habalgo TO habalgo_admin;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA habalgo TO habalgo_app;

-- 8. Enforce Default Privileges for Future Objects
ALTER DEFAULT PRIVILEGES IN SCHEMA habalgo 
    GRANT ALL ON TABLES TO habalgo_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA habalgo 
    GRANT SELECT, INSERT, UPDATE ON TABLES TO habalgo_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA habalgo 
    GRANT SELECT ON TABLES TO habalgo_auditor;

ALTER DEFAULT PRIVILEGES IN SCHEMA habalgo 
    GRANT USAGE, SELECT ON SEQUENCES TO habalgo_app;
```

---

## 5. Verification of Least Privilege Enforcement

During Phase 5 testing in the restored test database (`grp00_habalgodb_activity6_restore_test`), least privilege enforcement was empirically proven:

1. **Permitted Action (`habalgo_app`):**
   - Executed: `SELECT count(*) FROM habalgo.customer;`
   - Outcome: **PASS** (Zero errors, returned integer row count).
2. **Blocked Action (`habalgo_app`):**
   - Executed: `DELETE FROM habalgo.customer WHERE customer_id = 999;`
   - Outcome: **PASS** (Blocked by PostgreSQL engine with `ERROR: permission denied for table customer`).
3. **Permitted Action (`habalgo_auditor`):**
   - Executed: `SELECT count(*) FROM habalgo.booking;`
   - Outcome: **PASS** (Zero errors, read query succeeded).
4. **Blocked Action (`habalgo_auditor`):**
   - Executed: `INSERT INTO habalgo.customer VALUES (...);`
   - Outcome: **PASS** (Blocked by PostgreSQL engine with `ERROR: permission denied for table customer`).

