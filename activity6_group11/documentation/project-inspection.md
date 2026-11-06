# Phase 1 — Project Inspection Report: BoardTrack

**Course:** COMP 018 — Database Administration  
**Activity:** Activity 6: Database Backup, Restoration, and Recovery  
**Project:** BoardTrack — Boarding House & Rental Management System  
**Date:** 2026-11-06  
**Auditor / DBA:** Senior PostgreSQL Database Administrator  

---

## 1. Executive Summary

This Project Inspection Report provides a comprehensive architectural and operational baseline audit of the **BoardTrack — Boarding House & Rental Management System** repository. The audit investigates all configuration files, application connection scripts, SQL migration and seed scripts, documentation artifacts, and live PostgreSQL cluster states to establish the ground truth for Activity 6 (Database Backup, Restoration, and Recovery).

All findings reflect verbatim repository contents and verified live PostgreSQL 18.6 catalog inspection. In strict compliance with database safety policies and COMP 018 directives, no credentials or secrets are disclosed, and live cluster state is verified non-destructively.

---

## 2. Repository Artifacts Inspected

The following files and directories were inspected during Phase 1:

| Artifact Path | Description & Role in Architecture |
|---|---|
| `README.md` | Primary setup guide detailing prerequisites (Node 20.12+, PostgreSQL 13+), default database configuration (`boardtrack_db`), installation steps, demo accounts, and testing procedures. |
| `.env.example` | Template environment configuration specifying connection string format `postgresql://USER:PASSWORD@HOST:PORT/DATABASE` and target database `boardtrack_db`. |
| `.gitignore` | Version control ignore rules (currently ignores `node_modules/` and `.env`). |
| `package.json` | Node.js project manifest defining dependencies (`express`, `ejs`, `pg`, `express-session`) and management scripts (`db:setup`, `db:migrate`, `db:seed`, `db:reset`, `db:bundle`). |
| `src/db.js` | Core connection layer instantiating `pg.Pool` from `process.env.DATABASE_URL` with date parser override (OID 1082). |
| `src/auth.js` | Application security module defining the Role-Based Access Control (RBAC) permission matrix and bcrypt verification using PostgreSQL `pgcrypto.crypt()`. |
| `src/bootstrap.js` | Database initialization engine managing automatic database creation (`ensureDatabase`), migration execution (`migrate`), and seed loading (`seed`). |
| `scripts/db.js` | Command-line management runner exposing CLI actions: `setup`, `migrate`, `seed`, `reset`, `bundle`. |
| `src/server.js` | Express server entry point mounting routes, session middleware, and static assets. |
| `src/routes/*.js` | Route controllers for `properties`, `rooms`, `tenants`, `leases`, `payments`, `bills`, and `home`. |
| `db/migrations/001_schema.sql` | Authoritative DDL migration script defining extensions, tables, constraints, indexes, triggers, and views. |
| `db/seeds/001_sample_data.sql` | Seed script providing initial property, room, tenant, lease, payment, bill, and user records. |
| `db/boardtrack_full_setup.sql` | Bundled standalone SQL script containing schema migrations and seed data in a single transactional block. |
| `docs/database.md` | Authoritative database design documentation detailing normalization, data types, constraints, and triggers. |
| `docs/user-roles.md` | Access control blueprint specifying application roles vs. intended PostgreSQL cluster roles. |
| `docs/troubleshooting.md` | Diagnostic reference for connection, migration, extension, and constraint errors. |
| `docs/how-it-works.md` & `docs/ai-usage.md` | Architectural flow descriptions and AI disclosure documentation. |
| `Group Test/` | Peer activity reports and evidence from Activity 3, Activity 4, Activity 5, and Activity 6 (CampusSafe & ParkIT). |
| `../activity5_group11/` | Historical Activity 5 database maintenance report, SQL check scripts, and live query results from 2026-11-06. |

---

## 3. Detailed Technical Inspection Findings

### 3.1 Actual PostgreSQL Database Name
* **Discovered Database Name:** `boardtrack_db`
* **Evidence Sources:**
  - `README.md` (Line 31): `psql -U postgres -c "CREATE DATABASE boardtrack_db;"`
  - `.env.example` (Line 3): `DATABASE_URL=postgresql://your_db_user:your_password_user@localhost:5432/boardtrack_db`
  - `docs/database.md` (Line 3): `- Database: boardtrack_db (name is configurable through DATABASE_URL)`
  - `src/bootstrap.js` (Line 16): Extracts database name dynamically from `process.env.DATABASE_URL` pathname.
  - `../activity5_group11/activity5_report.md` (Line 5): Identifies target database as `boardtrack_db`.
* **Database Presence on Live Cluster:** Checked via `SELECT datname FROM pg_database WHERE datname = 'boardtrack_db';`. **Result: 0 rows (Database does NOT exist on the live cluster).**

### 3.2 Database Connection Configuration
* **Connection Provider:** Node.js `pg` library (`pg.Pool` pooler in `src/db.js`).
* **Connection Parameterization:** Driven entirely by `process.env.DATABASE_URL`.
* **Standard Format:** `postgresql://<username>:<password>@<hostname>:<port>/<database>`
* **Host & Port:** `localhost:5432` (PostgreSQL default port).
* **Live Service Status:** Active and responding on `localhost:5432` (`PostgreSQL 18.6 on x86_64-windows, compiled by msvc-19.44.35228, 64-bit`).
* **Authentication Mechanism:** Client authentication governed by `pg_hba.conf` using `scram-sha-256`. Local administrative access achieved non-interactively via `%APPDATA%\postgresql\pgpass.conf`.
* **Application Bootstrapping Flags:**
  - `AUTO_CREATE_DB`: `true` (Attempts `CREATE DATABASE "boardtrack_db"` via administrative connection to `/postgres` if missing).
  - `AUTO_SETUP`: `true` (Applies pending migrations if `schema_migrations` table is unpopulated).
  - `AUTO_SEED`: `true` (Populates seed data if table row counts are zero).

---

### 3.3 Database Tables and Entity Naming
The repository schema utilizes strictly normalized, singular table naming conventions:

| Configured / Actual Table Name | Prompt Reference Label | Entity Purpose |
|---|---|---|
| `property` | `properties` | Physical boarding houses and apartment complexes. |
| `room` | `rooms` | Individual rentable accommodation units within properties. |
| `tenant` | `tenants` | Registered individuals renting rooms. |
| `lease` | `leases` | Legal rental contracts binding tenants, rooms, and date intervals. |
| `payment` | `payments` | Financial transactions recorded against specific leases. |
| `utility_bill` | `utility_bills` | Monthly utility consumption charges billed to leases. |
| `app_user` | `app_user` | Authentication credentials, system roles, and tenant associations. |
| `schema_migrations` | *(system/meta)* | Tracks applied DDL migrations (`name`, `applied_at`). |

> **Architectural Note:** The actual database tables use singular names (`property`, `room`, `tenant`, `lease`, `payment`, `utility_bill`), whereas the prompt refers to colloquial plural business names (`properties`, `rooms`, `tenants`, etc.). All administrative and backup procedures must target the exact singular relation names.

---

### 3.4 Columns, Data Types, and Nullability

```sql
-- 1. property
property_id   SERIAL PRIMARY KEY
property_name VARCHAR(100) NOT NULL
address       VARCHAR(255) NOT NULL

-- 2. room
room_id      SERIAL PRIMARY KEY
property_id  INT NOT NULL REFERENCES property(property_id)
room_number  VARCHAR(20) NOT NULL
monthly_rate NUMERIC(10,2) NOT NULL
status       VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE'

-- 3. tenant
tenant_id       SERIAL PRIMARY KEY
full_name       VARCHAR(100) NOT NULL
contact_number  VARCHAR(20) NOT NULL
email           VARCHAR(100) NULL UNIQUE
valid_id_number VARCHAR(50) NULL

-- 4. lease
lease_id      SERIAL PRIMARY KEY
tenant_id     INT NOT NULL REFERENCES tenant(tenant_id)
room_id       INT NOT NULL REFERENCES room(room_id)
start_date    DATE NOT NULL
end_date      DATE NOT NULL
moved_out_on  DATE NULL
monthly_rent  NUMERIC(10,2) NOT NULL
status        VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'

-- 5. payment
payment_id     SERIAL PRIMARY KEY
lease_id       INT NOT NULL REFERENCES lease(lease_id)
payment_date   DATE NOT NULL DEFAULT CURRENT_DATE
amount         NUMERIC(10,2) NOT NULL
payment_method VARCHAR(30) NOT NULL
status         VARCHAR(20) NOT NULL DEFAULT 'COMPLETED'

-- 6. utility_bill
utility_bill_id SERIAL PRIMARY KEY
lease_id        INT NOT NULL REFERENCES lease(lease_id)
billing_period  DATE NOT NULL
utility_type    VARCHAR(30) NOT NULL
amount          NUMERIC(10,2) NOT NULL
status          VARCHAR(20) NOT NULL DEFAULT 'UNPAID'

-- 7. app_user
user_id       SERIAL PRIMARY KEY
username      VARCHAR(50) NOT NULL UNIQUE
password_hash TEXT NOT NULL
role          VARCHAR(20) NOT NULL
tenant_id     INT NULL REFERENCES tenant(tenant_id)
is_active     BOOLEAN NOT NULL DEFAULT TRUE

-- 8. schema_migrations
name          TEXT PRIMARY KEY
applied_at    TIMESTAMPTZ DEFAULT now()
```

---

### 3.5 Primary Keys
1. `property`: `property_id` (Integer, auto-incrementing via sequence)
2. `room`: `room_id` (Integer, auto-incrementing via sequence)
3. `tenant`: `tenant_id` (Integer, auto-incrementing via sequence)
4. `lease`: `lease_id` (Integer, auto-incrementing via sequence)
5. `payment`: `payment_id` (Integer, auto-incrementing via sequence)
6. `utility_bill`: `utility_bill_id` (Integer, auto-incrementing via sequence)
7. `app_user`: `user_id` (Integer, auto-incrementing via sequence)
8. `schema_migrations`: `name` (Text)

---

### 3.6 Foreign Keys and Referential Integrity
* `room.property_id` $\to$ `property(property_id)` (`ON DELETE NO ACTION`)
* `lease.tenant_id` $\to$ `tenant(tenant_id)` (`ON DELETE NO ACTION`)
* `lease.room_id` $\to$ `room(room_id)` (`ON DELETE NO ACTION`)
* `payment.lease_id` $\to$ `lease(lease_id)` (`ON DELETE NO ACTION`)
* `utility_bill.lease_id` $\to$ `lease(lease_id)` (`ON DELETE NO ACTION`)
* `app_user.tenant_id` $\to$ `tenant(tenant_id)` (`ON DELETE NO ACTION`)

> **Referential Integrity Guarantee:** All foreign keys deliberately omit `CASCADE`, adopting `ON DELETE NO ACTION`. This guarantees that historical lease contracts, tenant audit records, payments, and utility bills cannot be accidentally orphaned or purged by cascading deletes.

---

### 3.7 Unique Constraints
1. `room`: `CONSTRAINT uq_room_per_property UNIQUE (property_id, room_number)`
2. `tenant`: `UNIQUE (email)` (Allows multiple NULLs, enforces uniqueness on non-null values)
3. `app_user`: `UNIQUE (username)`

---

### 3.8 Check and Exclusion Constraints
* `room.monthly_rate`: `CHECK (monthly_rate > 0)`
* `room.status`: `CHECK (status IN ('AVAILABLE','OCCUPIED','MAINTENANCE'))`
* `lease.monthly_rent`: `CHECK (monthly_rent > 0)`
* `lease.status`: `CHECK (status IN ('ACTIVE','TERMINATED','EXPIRED'))`
* `lease.ck_lease_dates`: `CHECK (end_date > start_date)`
* `lease.ck_lease_moveout`: `CHECK (moved_out_on IS NULL OR moved_out_on >= start_date)`
* `lease.ex_lease_no_overlap` *(PostgreSQL GiST Exclusion Constraint)*:
  ```sql
  CONSTRAINT ex_lease_no_overlap EXCLUDE USING gist (
      room_id WITH =,
      daterange(start_date, end_date, '[]') WITH &&
  ) WHERE (status = 'ACTIVE')
  ```
  *Requires PostgreSQL extension `btree_gist`.* Ensures that no two active leases for the same room overlap in calendar duration.
* `payment.amount`: `CHECK (amount > 0)`
* `payment.payment_method`: `CHECK (payment_method IN ('CASH','GCASH','BANK_TRANSFER'))`
* `payment.status`: `CHECK (status IN ('COMPLETED','PENDING','FAILED'))`
* `utility_bill.billing_period`: `CHECK (EXTRACT(DAY FROM billing_period) = 1)` (Enforces that bills are registered on the 1st day of the billing month).
* `utility_bill.utility_type`: `CHECK (utility_type IN ('ELECTRICITY','WATER','INTERNET'))`
* `utility_bill.amount`: `CHECK (amount >= 0)`
* `utility_bill.status`: `CHECK (status IN ('UNPAID','PAID'))`
* `app_user.role`: `CHECK (role IN ('admin','staff','tenant'))`
* `app_user.ck_tenant_user`: `CHECK ((role = 'tenant') = (tenant_id IS NOT NULL))` (Guarantees that `tenant_id` is populated if and only if role is `'tenant'`).

---

### 3.9 Indexes
1. `idx_lease_room` ON `lease(room_id)` (B-tree)
2. `idx_lease_tenant` ON `lease(tenant_id)` (B-tree)
3. `idx_payment_lease` ON `payment(lease_id)` (B-tree)
4. `idx_utility_lease` ON `utility_bill(lease_id)` (B-tree)
5. Underlying implicit indexes:
   - Primary key unique B-tree indexes for all 7 tables.
   - `uq_room_per_property` B-tree index on `room(property_id, room_number)`.
   - Unique B-tree indexes on `tenant(email)` and `app_user(username)`.
   - GiST index backing `ex_lease_no_overlap` on `lease`.

---

### 3.10 Sequences
1. `property_property_id_seq`
2. `room_room_id_seq`
3. `tenant_tenant_id_seq`
4. `lease_lease_id_seq`
5. `payment_payment_id_seq`
6. `utility_bill_utility_bill_id_seq`
7. `app_user_user_id_seq`

---

### 3.11 Views and Triggers
* **View `v_lease_summary`:**
  ```sql
  CREATE VIEW v_lease_summary AS
  SELECT l.lease_id, l.tenant_id, t.full_name AS tenant, p.property_name, r.room_number,
         l.start_date, l.end_date, l.monthly_rent, l.status,
         COALESCE((SELECT SUM(x.amount) FROM payment x
                   WHERE x.lease_id = l.lease_id AND x.status = 'COMPLETED'), 0) AS total_paid,
         COALESCE((SELECT SUM(u.amount) FROM utility_bill u
                   WHERE u.lease_id = l.lease_id), 0) AS utilities_billed
  FROM lease l
  JOIN tenant t   ON t.tenant_id = l.tenant_id
  JOIN room r     ON r.room_id = l.room_id
  JOIN property p ON p.property_id = r.property_id;
  ```
* **Trigger Functions and Triggers:**
  - `sync_room_status()` $\to$ `trg_lease_sync_room`: Fires AFTER INSERT, UPDATE of status/room, or DELETE on `lease`. Automatically toggles room status between `OCCUPIED` and `AVAILABLE` based on the existence of ACTIVE leases (leaves `MAINTENANCE` status untouched).
  - `guard_room_status()` $\to$ `trg_room_status_guard`: Fires BEFORE INSERT or UPDATE of status on `room`. Blocks invalid manual status changes that contradict active leases.

---

### 3.12 Database Users and Roles

#### Intended Roles (from `docs/user-roles.md`):
1. `boardtrack_owner`: Database owner role; used for schema creation and migrations. NOLOGIN or restricted LOGIN.
2. `boardtrack_admin_grp`: Administrative group role with full DML access to business tables, but strictly no SUPERUSER or CREATEROLE privileges.
3. `app_runtime_grp`: Runtime group role with SELECT, INSERT, UPDATE on business tables, restricted DELETE, USAGE on sequences, and SELECT on `v_lease_summary` and `app_user`.
4. `app_readonly_grp`: Read-only reporting group with SELECT access on business tables and `v_lease_summary`.
5. `boardtrack_app`: Dedicated application LOGIN role belonging to `app_runtime_grp`.

#### Live PostgreSQL Cluster Verification:
Inspection query executed on live cluster:
```sql
SELECT rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole
FROM pg_roles
WHERE rolname IN ('boardtrack_owner', 'boardtrack_admin_grp', 'app_runtime_grp', 'app_readonly_grp', 'boardtrack_app')
   OR rolname LIKE '%boardtrack%';
```
* **Result:** **0 rows returned.**
* **Conclusion:** None of the custom project roles exist on the live PostgreSQL 18 cluster. Only built-in superuser `postgres` and default system roles (`pg_*`) are present.

---

### 3.13 Role Memberships
* **Intended:** `boardtrack_app` is a member of `app_runtime_grp`.
* **Live Cluster:** No project memberships exist.

---

### 3.14 Database and Schema Privileges
* **Intended:** Strict least-privilege isolation:
  - Database `boardtrack_db`: CONNECT granted to `boardtrack_admin_grp`, `app_runtime_grp`, `app_readonly_grp`.
  - Schema `public`: USAGE granted to `boardtrack_admin_grp`, `app_runtime_grp`, `app_readonly_grp`.
  - Sequences: USAGE granted to `boardtrack_admin_grp` and `app_runtime_grp`.
* **Live Cluster:** Schema `public` has default standard PostgreSQL privileges; no project-specific grants exist.

---

### 3.15 Existing Sample Records (from `db/seeds/001_sample_data.sql`)
1. **Properties (2):**
   - ID 1: 'Sunshine Boarding House', '12 Rizal St., Calamba, Laguna'
   - ID 2: 'Greenview Apartments', '45 Mabini Ave., Los Banos, Laguna'
2. **Rooms (6):**
   - Property 1: Room 101 (3500.00, AVAILABLE), Room 102 (3500.00, AVAILABLE), Room 103 (4000.00, AVAILABLE)
   - Property 2: Room A1 (5000.00, AVAILABLE), Room A2 (5000.00, AVAILABLE), Room A3 (5500.00, MAINTENANCE)
3. **Tenants (4):**
   - ID 1: 'Juan Dela Cruz', '09171234567', 'juan@example.com', 'STU-2023-0001'
   - ID 2: 'Maria Santos', '09181234567', 'maria@example.com', 'DL-N01-23-000123'
   - ID 3: 'Pedro Reyes', '09191234567', NULL, 'UMID-0001-2345'
   - ID 4: 'Ana Lopez', '09201234567', 'ana@example.com', NULL
4. **Leases (4):**
   - ID 1: Tenant 1, Room 1, 2026-01-01 to 2026-12-31, 3500.00, ACTIVE
   - ID 2: Tenant 2, Room 2, 2026-02-01 to 2027-01-31, 3500.00, ACTIVE
   - ID 3: Tenant 3, Room 4, 2026-03-01 to 2027-02-28, 5000.00, ACTIVE
   - ID 4: Tenant 4, Room 1, 2025-01-01 to 2025-12-31, moved out 2025-11-30, 3300.00, TERMINATED
5. **Payments (6):**
   - Lease 1: 3500.00 (CASH, COMPLETED), 3500.00 (GCASH, COMPLETED), 3500.00 (GCASH, PENDING)
   - Lease 2: 3500.00 (CASH, COMPLETED)
   - Lease 3: 5000.00 (BANK_TRANSFER, COMPLETED)
   - Lease 4: 3300.00 (CASH, COMPLETED)
6. **Utility Bills (4):**
   - Lease 1: 2026-01-01 ELECTRICITY 420.50 (PAID); 2026-01-01 WATER 150.00 (PAID)
   - Lease 2: 2026-02-01 ELECTRICITY 380.00 (UNPAID)
   - Lease 3: 2026-03-01 INTERNET 700.00 (UNPAID)
7. **Application Users (3):**
   - `landlord`: role 'admin', tenant_id NULL, bcrypt password hash
   - `caretaker`: role 'staff', tenant_id NULL, bcrypt password hash
   - `juan`: role 'tenant', tenant_id 1, bcrypt password hash

---

### 3.16 Application Database Permissions (Web Layer vs. Database Layer)
* **Single Connection Architecture:** Node.js Express backend connects using a single connection string (`process.env.DATABASE_URL`).
* **Web Layer RBAC (`src/auth.js`):**
  - `admin`: Full CRUD on all modules (`properties`, `rooms`, `tenants`, `leases`, `payments`, `bills`).
  - `staff`: Read properties; Read/Update rooms; Create/Read/Update tenants, leases, payments, bills; No DELETE permissions.
  - `tenant`: Read-only access to own leases, payments, and bills (row-level filtering keyed to `app_user.tenant_id`).
* **Database Layer:** Intended to reinforce web-layer RBAC by connecting through `boardtrack_app` (`app_runtime_grp`), preventing arbitrary DDL operations or unchecked table truncation.

---

### 3.17 Existing Backup and Recovery Procedures
* **Repository Findings:** No backup, restoration, or disaster recovery scripts were previously committed to the repository.
* **Activity 5 State:** Activity 5 concluded on 2026-11-06 with a verified finding that `boardtrack_db` had not been provisioned on the cluster, halting maintenance queries.
* **Activity 6 Mandate:** This activity formulates and deploys the formal enterprise backup policy, automated PowerShell procedures (`backup.ps1`, `restore.ps1`), verification frameworks (`verification.sql`), and disaster recovery simulation models (`recovery-simulation.sql`).

---

## 4. Gap Analysis and Identified Missing Information

1. **Target Database Not Initialized on Live Cluster:** The actual database name is `boardtrack_db`. However, `boardtrack_db` does not currently exist on the live PostgreSQL 18 cluster (`FATAL: database "boardtrack_db" does not exist`).
2. **Cluster Roles Unprovisioned:** The intended roles from `docs/user-roles.md` (`boardtrack_owner`, `boardtrack_admin_grp`, `app_runtime_grp`, `app_readonly_grp`, `boardtrack_app`) exist only as DDL documentation and have not been executed on the live cluster.
3. **Absence of Local `.env` File:** The repository contains `.env.example` but no active `.env` file (which is correct and expected to avoid committing credentials).
4. **Backup Exclusion in `.gitignore`:** The existing `.gitignore` covers `node_modules/` and `.env` but does not explicitly block PostgreSQL dump files (`*.dump`, `*.tar`, `*.backup`, `*.sql`). This must be remediated in Phase 8.

---

## 5. Phase 1 Sign-Off

* **Actual Database Name Identified:** `boardtrack_db`
* **Schema Integrity Verified:** Yes, fully documented from `001_schema.sql` and `001_sample_data.sql`.
* **Live Service Status Verified:** Yes, PostgreSQL 18.6 active on `localhost:5432`.
* **Prerequisite Condition:** Database `boardtrack_db` is unprovisioned on the live host. In strict adherence to Safety Rule 3 ("Never initialize or reseed the original database") and the Phase 3 Directive ("If it does not exist, stop database execution. Do not initialize or recreate it"), live dump extraction cannot proceed against a non-existent database, and all prepared administrative assets will be safely built and documented.

**Report Status:** COMPLETE AND AUDITED  
**Next Phase:** Phase 2 — Backup Planning (`backup-plan.md`)

