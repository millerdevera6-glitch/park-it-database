# Phase 1: Project Inspection Report
## Project: BoardTrack – Property and Rental Management System
**Course:** COMP 018 – Database Administration  
**Activity:** Activity 6 – Database Backup, Restoration, and Recovery  
**Inspection Date:** 2026-11-06  
**Inspector:** Senior PostgreSQL DBA, Node.js Developer & Technical Documentation Specialist  

---

### 1. Executive Summary & Repository Origin

The BoardTrack project is a web-based property, boarding house, and rental management system designed for landlords and property caretakers. It manages buildings, rentable rooms, tenant records, leasing agreements, rent payments, and utility billings. Integrity rules (such as lease date consistency, payment validity, and room occupancy status synchronization) are enforced directly within the PostgreSQL database layer using foreign keys, check constraints, triggers, and a GiST exclusion constraint.

- **GitHub Repository:** `https://github.com/karlrobertc-art/BoardTrack.git`
- **Application Platform:** Node.js (>= 20.12), Express 4.19, EJS 3.1, `pg` 8.12 (`pg.Pool`), `express-session` 1.18
- **Database Engine:** PostgreSQL 18 (developed for PostgreSQL 18; compatible with PostgreSQL 13+)
- **Extensions Utilized:** 
  - `btree_gist` (mandatory for multi-column GiST exclusion constraints on scalar data types)
  - `pgcrypto` (used for bcrypt password hashing via `crypt()` and `gen_salt('bf')`)

---

### 2. Database Name & Connection Configuration

#### 2.1 Confirmation of Actual Database Name
Following a rigorous audit of repository configuration files, SQL migration scripts, documentation, and bootstrapping routines:
- **`README.md`:** Explicitly references `boardtrack_db` (e.g., instructions state `psql -U postgres -c "CREATE DATABASE boardtrack_db;"`).
- **`.env.example`:** Defines default connection string format:
  `DATABASE_URL=postgresql://your_db_user:your_password_user@localhost:5432/boardtrack_db`
- **`docs/database.md`:** Identifies `- **Database:** boardtrack_db (name is configurable through DATABASE_URL) · **Schema:** public`.
- **`src/bootstrap.js`:** Dynamically parses `DATABASE_URL` and passes the target database name (defaulting to `boardtrack_db`) to `CREATE DATABASE "..."` if `AUTO_CREATE_DB` is enabled.
- **Confirmed Database Name:** `boardtrack_db`

#### 2.2 Connection Architecture
The application centralizes database connectivity in `src/db.js`:
- Utilizes `pg.Pool` initialized with `connectionString: process.env.DATABASE_URL`.
- Overrides type parser `1082` (PostgreSQL `DATE`) to return raw `'YYYY-MM-DD'` ISO strings, preventing client-side timezone offsets from distorting lease and payment dates.
- Exports a single query helper: `module.exports = { query: (sql, values = []) => pool.query(sql, values) }`.

---

### 3. Database Schema: Tables, Columns, and Data Types

The database consists of eight (8) base tables in schema `public`:

| Table Name | Column Name | Data Type | Nullable | Default | Description |
|---|---|---|---|---|---|
| **`property`** | `property_id` | `SERIAL` (INTEGER) | NO | `nextval('property_property_id_seq')` | Primary Key |
| | `property_name` | `VARCHAR(100)` | NO | None | Name of property/building |
| | `address` | `VARCHAR(255)` | NO | None | Physical address |
| **`room`** | `room_id` | `SERIAL` (INTEGER) | NO | `nextval('room_room_id_seq')` | Primary Key |
| | `property_id` | `INTEGER` | NO | None | Foreign Key referencing `property` |
| | `room_number` | `VARCHAR(20)` | NO | None | Room identification number/code |
| | `monthly_rate` | `NUMERIC(10,2)` | NO | None | Base monthly rental rate (> 0) |
| | `status` | `VARCHAR(20)` | NO | `'AVAILABLE'` | Room state: AVAILABLE, OCCUPIED, MAINTENANCE |
| **`tenant`** | `tenant_id` | `SERIAL` (INTEGER) | NO | `nextval('tenant_tenant_id_seq')` | Primary Key |
| | `full_name` | `VARCHAR(100)` | NO | None | Complete legal name |
| | `contact_number` | `VARCHAR(20)` | NO | None | Phone or mobile contact |
| | `email` | `VARCHAR(100)` | YES | None | Email address (Unique) |
| | `valid_id_number` | `VARCHAR(50)` | YES | None | Government or student ID number |
| **`lease`** | `lease_id` | `SERIAL` (INTEGER) | NO | `nextval('lease_lease_id_seq')` | Primary Key |
| | `tenant_id` | `INTEGER` | NO | None | Foreign Key referencing `tenant` |
| | `room_id` | `INTEGER` | NO | None | Foreign Key referencing `room` |
| | `start_date` | `DATE` | NO | None | Lease agreement start date |
| | `end_date` | `DATE` | NO | None | Lease agreement expiration date |
| | `moved_out_on` | `DATE` | YES | None | Actual move-out date |
| | `monthly_rent` | `NUMERIC(10,2)` | NO | None | Contractual monthly rate (> 0) |
| | `status` | `VARCHAR(20)` | NO | `'ACTIVE'` | ACTIVE, TERMINATED, EXPIRED |
| **`payment`** | `payment_id` | `SERIAL` (INTEGER) | NO | `nextval('payment_payment_id_seq')` | Primary Key |
| | `lease_id` | `INTEGER` | NO | None | Foreign Key referencing `lease` |
| | `payment_date` | `DATE` | NO | `CURRENT_DATE` | Date payment was recorded |
| | `amount` | `NUMERIC(10,2)` | NO | None | Payment amount (> 0) |
| | `payment_method` | `VARCHAR(30)` | NO | None | CASH, GCASH, BANK_TRANSFER |
| | `status` | `VARCHAR(20)` | NO | `'COMPLETED'` | COMPLETED, PENDING, FAILED |
| **`utility_bill`** | `utility_bill_id` | `SERIAL` (INTEGER) | NO | `nextval('utility_bill_utility_bill_id_seq')` | Primary Key |
| | `lease_id` | `INTEGER` | NO | None | Foreign Key referencing `lease` |
| | `billing_period` | `DATE` | NO | None | 1st day of billing month |
| | `utility_type` | `VARCHAR(30)` | NO | None | ELECTRICITY, WATER, INTERNET |
| | `amount` | `NUMERIC(10,2)` | NO | None | Billed utility amount (>= 0) |
| | `status` | `VARCHAR(20)` | NO | `'UNPAID'` | UNPAID, PAID |
| **`app_user`** | `user_id` | `SERIAL` (INTEGER) | NO | `nextval('app_user_user_id_seq')` | Primary Key |
| | `username` | `VARCHAR(50)` | NO | None | Unique login handle |
| | `password_hash` | `TEXT` | NO | None | Bcrypt hashed password |
| | `role` | `VARCHAR(20)` | NO | None | Application role: admin, staff, tenant |
| | `tenant_id` | `INTEGER` | YES | None | Foreign Key referencing `tenant` (tenant role only) |
| | `is_active` | `BOOLEAN` | NO | `TRUE` | Account status flag |
| **`schema_migrations`** | `name` | `TEXT` | NO | None | Primary Key; migration script filename |
| | `applied_at` | `TIMESTAMPTZ` | YES | `now()` | Migration execution timestamp |

---

### 4. Constraints Inventory

#### 4.1 Primary Keys
- `property_pkey` PRIMARY KEY (`property_id`)
- `room_pkey` PRIMARY KEY (`room_id`)
- `tenant_pkey` PRIMARY KEY (`tenant_id`)
- `lease_pkey` PRIMARY KEY (`lease_id`)
- `payment_pkey` PRIMARY KEY (`payment_id`)
- `utility_bill_pkey` PRIMARY KEY (`utility_bill_id`)
- `app_user_pkey` PRIMARY KEY (`user_id`)
- `schema_migrations_pkey` PRIMARY KEY (`name`)

#### 4.2 Foreign Keys
All foreign keys utilize PostgreSQL's standard default behavior (`ON DELETE NO ACTION`, `ON UPDATE NO ACTION`), preventing silent cascading deletes and preserving legal/financial audit trails:
- `room_property_id_fkey`: `room(property_id)` REFERENCES `property(property_id)`
- `lease_tenant_id_fkey`: `lease(tenant_id)` REFERENCES `tenant(tenant_id)`
- `lease_room_id_fkey`: `lease(room_id)` REFERENCES `room(room_id)`
- `payment_lease_id_fkey`: `payment(lease_id)` REFERENCES `lease(lease_id)`
- `utility_bill_lease_id_fkey`: `utility_bill(lease_id)` REFERENCES `lease(lease_id)`
- `app_user_tenant_id_fkey`: `app_user(tenant_id)` REFERENCES `tenant(tenant_id)`

#### 4.3 Unique Constraints
- `uq_room_per_property`: UNIQUE (`property_id`, `room_number`)
- `tenant_email_key`: UNIQUE (`email`)
- `app_user_username_key`: UNIQUE (`username`)

#### 4.4 Check Constraints
- `room.monthly_rate`: `CHECK (monthly_rate > 0)`
- `room.status`: `CHECK (status IN ('AVAILABLE','OCCUPIED','MAINTENANCE'))`
- `lease.monthly_rent`: `CHECK (monthly_rent > 0)`
- `lease.status`: `CHECK (status IN ('ACTIVE','TERMINATED','EXPIRED'))`
- `lease.ck_lease_dates`: `CHECK (end_date > start_date)`
- `lease.ck_lease_moveout`: `CHECK (moved_out_on IS NULL OR moved_out_on >= start_date)`
- `payment.amount`: `CHECK (amount > 0)`
- `payment.payment_method`: `CHECK (payment_method IN ('CASH','GCASH','BANK_TRANSFER'))`
- `payment.status`: `CHECK (status IN ('COMPLETED','PENDING','FAILED'))`
- `utility_bill.billing_period`: `CHECK (EXTRACT(DAY FROM billing_period) = 1)`
- `utility_bill.utility_type`: `CHECK (utility_type IN ('ELECTRICITY','WATER','INTERNET'))`
- `utility_bill.amount`: `CHECK (amount >= 0)`
- `utility_bill.status`: `CHECK (status IN ('UNPAID','PAID'))`
- `app_user.role`: `CHECK (role IN ('admin','staff','tenant'))`
- `app_user.ck_tenant_user`: `CHECK ((role = 'tenant') = (tenant_id IS NOT NULL))`

#### 4.5 Exclusion Constraints (Business Rule 2)
- **`ex_lease_no_overlap`**:
  ```sql
  CONSTRAINT ex_lease_no_overlap EXCLUDE USING gist
    (room_id WITH =, daterange(start_date, end_date, '[]') WITH &&)
    WHERE (status = 'ACTIVE')
  ```
  Guarantees that no two `ACTIVE` lease records for the same physical `room_id` can have overlapping date intervals.

---

### 5. Indexes and Sequences

#### 5.1 Secondary Indexes
- `idx_lease_room` ON `lease(room_id)`
- `idx_lease_tenant` ON `lease(tenant_id)`
- `idx_payment_lease` ON `payment(lease_id)`
- `idx_utility_lease` ON `utility_bill(lease_id)`

#### 5.2 Sequences
- `property_property_id_seq`
- `room_room_id_seq`
- `tenant_tenant_id_seq`
- `lease_lease_id_seq`
- `payment_payment_id_seq`
- `utility_bill_utility_bill_id_seq`
- `app_user_user_id_seq`

---

### 6. Views, Functions, and Triggers

#### 6.1 View: `v_lease_summary`
Provides real-time denormalized calculations of total rent paid and utility charges per lease without storing derived balance fields:
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

#### 6.2 Functions & Triggers
- **`sync_room_status()`** (Trigger: `trg_lease_sync_room`):
  Fires AFTER INSERT OR UPDATE OF `status`, `room_id` OR DELETE ON `lease`. Sets `room.status` to `'OCCUPIED'` if an ACTIVE lease exists, or `'AVAILABLE'` otherwise (skipping `'MAINTENANCE'`).
- **`guard_room_status()`** (Trigger: `trg_room_status_guard`):
  Fires BEFORE INSERT OR UPDATE OF `status` ON `room`. Rejects illegal manual status changes that contradict active lease records.

---

### 7. Sample Records Inventory

The canonical dataset defined in `db/seeds/001_sample_data.sql` contains:

1. **`property` (2 records):**
   - 1: 'Sunshine Boarding House', '12 Rizal St., Calamba, Laguna'
   - 2: 'Greenview Apartments', '45 Mabini Ave., Los Banos, Laguna'
2. **`room` (6 records):**
   - Property 1: Rooms '101' (3500), '102' (3500), '103' (4000)
   - Property 2: Rooms 'A1' (5000), 'A2' (5000), 'A3' (5500, MAINTENANCE)
3. **`tenant` (4 records):**
   - 1: 'Juan Dela Cruz', '09171234567', 'juan@example.com', 'STU-2023-0001'
   - 2: 'Maria Santos', '09181234567', 'maria@example.com', 'DL-N01-23-000123'
   - 3: 'Pedro Reyes', '09191234567', NULL, 'UMID-0001-2345'
   - 4: 'Ana Lopez', '09201234567', 'ana@example.com', NULL
4. **`lease` (4 records):**
   - 1: Tenant 1, Room 1 (2026-01-01 to 2026-12-31, rent 3500, ACTIVE)
   - 2: Tenant 2, Room 2 (2026-02-01 to 2027-01-31, rent 3500, ACTIVE)
   - 3: Tenant 3, Room 4 (2026-03-01 to 2027-02-28, rent 5000, ACTIVE)
   - 4: Tenant 4, Room 1 (2025-01-01 to 2025-12-31, moved out 2025-11-30, rent 3300, TERMINATED)
5. **`payment` (6 records):**
   - Lease 1: 2026-01-05 (3500, CASH, COMPLETED), 2026-02-05 (3500, GCASH, COMPLETED), 2026-03-07 (3500, GCASH, PENDING)
   - Lease 2: 2026-02-03 (3500, CASH, COMPLETED)
   - Lease 3: 2026-03-02 (5000, BANK_TRANSFER, COMPLETED)
   - Lease 4: 2025-10-05 (3300, CASH, COMPLETED)
6. **`utility_bill` (4 records):**
   - Lease 1: 2026-01-01 (ELECTRICITY, 420.50, PAID), 2026-01-01 (WATER, 150.00, PAID)
   - Lease 2: 2026-02-01 (ELECTRICITY, 380.00, UNPAID)
   - Lease 3: 2026-03-01 (INTERNET, 700.00, UNPAID)
7. **`app_user` (3 records):**
   - `landlord` (admin, bcrypt salt 'bf', tenant_id NULL)
   - `caretaker` (staff, bcrypt salt 'bf', tenant_id NULL)
   - `juan` (tenant, bcrypt salt 'bf', tenant_id 1)

---

### 8. Roles and Access Control Analysis

#### 8.1 Application-Layer Access Control (`src/auth.js`)
Application authorization is implemented through Express middleware using a centralized permission matrix:
- `properties`: admin: `crud`, staff: `r`
- `rooms`: admin: `crud`, staff: `ru`
- `tenants`: admin: `crud`, staff: `cru`
- `leases`: admin: `crud`, staff: `cru`, tenant: `r` (tenant filtered by `tenant_id`)
- `payments`: admin: `crud`, staff: `cru`, tenant: `r` (tenant filtered by `tenant_id`)
- `bills`: admin: `crud`, staff: `cru`, tenant: `r` (tenant filtered by `tenant_id`)

#### 8.2 Database-Layer Access Control (`docs/user-roles.md`)
The documented design plans five PostgreSQL roles for production:
1. **`boardtrack_owner`**: LOGIN, object owner, migration runner.
2. **`boardtrack_admin_grp`**: NOLOGIN group role for elevated administration.
3. **`app_runtime_grp`**: NOLOGIN group role for application runtime queries.
4. **`app_readonly_grp`**: NOLOGIN group role for read-only reporting.
5. **`boardtrack_app`**: LOGIN account member of `app_runtime_grp`.

#### 8.3 Live Cluster Role Status
Live inspection of the PostgreSQL 18 instance reveals:
- Current cluster roles: Only `postgres` (Superuser, Create role, Create DB, Replication, Bypass RLS) exists.
- The custom roles (`boardtrack_owner`, `boardtrack_admin_grp`, `app_runtime_grp`, `app_readonly_grp`, `boardtrack_app`) have not yet been instantiated in this PostgreSQL instance.

---

### 9. Cluster Status & Safety Findings

#### 9.1 Live Database Check on `localhost:5432`
- **PostgreSQL Service:** `postgresql-x64-18` is running and accepting TCP/IP connections on port 5432.
- **Database Presence Check:** Querying `pg_database` shows databases: `postgres`, `grp_binarysisters_projectdb`, `template1`, `template0`.
- **Finding:** The database `boardtrack_db` does not currently exist on the live cluster instance.

#### 9.2 Adherence to Safety Rules
Pursuant to the mandatory DBA Safety Directives:
- *Rule 3: Never initialize or reseed the original database.*
- *Safety Directive: If the database does not exist, stop database execution. Do not initialize or recreate it.*
- *Rule 9: Never fabricate successful results.*

Live dumping and modification operations on `boardtrack_db` were halted in accordance with DBA safety guidelines. All procedures, automation scripts (`backup.ps1`, `restore.ps1`), verification SQL (`verification.sql`), recovery workflows, and reports are fully formulated and validated against the canonical repository schema.

