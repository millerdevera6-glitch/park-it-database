# COMP 018 – Database Administration | Activity 6
## Phase 1: Comprehensive Project and Database Inspection Report
**Project Name:** HabalGo – Transportation & Booking Management System  
**Repository:** `https://github.com/jeanaroyo/HabalGo.git`  
**Inspection Date:** 2026-11-06  
**Lead DBA / Engineer:** Senior PostgreSQL Database Administrator (Student DBA)  

---

## 1. Executive Summary

This project inspection was conducted to establish the baseline architectural and configuration parameters for **HabalGo** prior to executing database backup, restoration, and recovery operations. HabalGo is a motorcycle ride-hailing and booking management application inspired by regional Philippine transport platforms (such as Angkas, JoyRide, and Move It). 

The inspection conclusively verified that HabalGo utilizes **PostgreSQL** as its database engine. The active operational database is **`grp00_habalgodb`**, hosted on **`localhost:5432`**, with all application tables encapsulated inside the custom schema **`habalgo`**.

---

## 2. Repository and Source Artifacts Audit

An exhaustive inspection of the HabalGo repository revealed the following structural composition:

| File / Component | Status | Findings and Architectural Significance |
| :--- | :--- | :--- |
| `README.md` | Present | Explicitly specifies PostgreSQL 15+ requirement, PHP 8.x PDO backend, MIT license, setup instructions specifying `grp00_habalgodb` and schema `habalgo`. |
| `config.php` | Present | Defines database connection array: host (`DB_HOST` / `localhost`), port (`DB_PORT` / `5432`), dbname (`DB_NAME` / `habalgo` falling back to environment), user (`DB_USER` / `postgres`). |
| `.env.example` | Present | Documents template configuration: `DB_HOST=localhost`, `DB_PORT=5432`, `DB_NAME=grp00_habalgodb`, `DB_USER=postgres`. |
| `.env` | Absent | Local environment override file is not committed, upholding credential hygiene. |
| `api.php` | Present | Implements 3-tier RESTful backend communicating via `PDO("pgsql:...")` with `SET search_path TO habalgo;` using prepared SQL statements. |
| `index.html` & `js/app.js` | Present | Single-page application frontend managing customer rides, driver dispatching, vehicle assignment, billing, and customer feedback. |
| `css/style.css` | Present | Styling interface for application dashboard and modal forms. |
| `schema.sql` | Present | Root DDL script creating schema `habalgo`, 8 relational tables, constraints, and secondary B-Tree indexes. |
| `sample data.sql` | Present | Root DML script providing sample driver records. |
| `database/01_schema.sql` | Present | Modular database initialization script identical in structure to root `schema.sql`. |
| `database/02_seed.sql` | Present | Seed data script defining initial driver and customer records. |
| `database/03_roles_and_privileges.sql` | Present | Activity 4 Access Control script establishing least-privilege group roles (`app_runtime_grp`, `app_readonly_grp`) and users. |
| `package.json` | Absent | Project does not use a Node.js runtime or build pipeline; pure vanilla JS/CSS. |
| `requirements.txt` | Absent | No Python runtime dependencies. |
| `composer.json` | Absent | No PHP Composer dependency manager required; native PDO PostgreSQL used. |
| `go.mod` | Absent | No Golang runtime dependencies. |
| `.gitignore` | Absent | **Action required:** Must be created to safeguard dumps (`*.dump`, `*.tar`, `*.bak`) and `.env`. |

---

## 3. Database Engine and Environmental Parameters

- **Database Engine:** PostgreSQL
- **Active Server Version:** PostgreSQL 18.6 on x86_64-windows, compiled by msvc-19.44.35229, 64-bit
- **PostgreSQL Binaries Path:** `C:\Program Files\PostgreSQL\18\bin\`
- **Database Name:** `grp00_habalgodb`
- **Application Schema:** `habalgo`
- **Host Address:** `localhost` (127.0.0.1 / ::1)
- **Port:** `5432`
- **Encoding:** `UTF8`
- **Collation / Ctype:** `English_Philippines.1252`
- **Connection Method:** PHP PDO PostgreSQL driver (`pdo_pgsql`) and PostgreSQL command line tools (`psql`, `pg_dump`, `pg_restore`, `createdb`).

---

## 4. Database Schema, Tables, and Structural Metadata

The HabalGo database architecture models a complete transportation ecosystem consisting of **8 relational tables** under schema `habalgo`:

```
habalgo (Schema)
 ├── customer (customer_id [PK], name, phone, email [UQ])
 ├── driver (driver_id [PK], name, phone, license_no [UQ])
 ├── vehicle (vehicle_id [PK], plate_no [UQ], vehicle_type, model)
 ├── driver_vehicle (driver_id [PK, FK], vehicle_id [PK, FK], assigned_from, assigned_to)
 ├── location (location_id [PK], address, city)
 ├── booking (booking_id [PK], customer_id [FK], driver_id [FK], pickup_location_id [FK], dropoff_location_id [FK], booking_date, booking_status)
 ├── payment (payment_id [PK], booking_id [FK], amount, method, status)
 └── rating_feedback (rating_id [PK], booking_id [FK], customer_id [FK], rating, feedback)
```

### Table Metadata Catalog

#### 1. `habalgo.customer`
- **Primary Key:** `customer_id` (INTEGER, SERIAL sequence: `customer_customer_id_seq`)
- **Columns:**
  - `customer_id`: INTEGER, NOT NULL, DEFAULT `nextval('habalgo.customer_customer_id_seq'::regclass)`
  - `name`: VARCHAR(100), NOT NULL
  - `phone`: VARCHAR(20), NOT NULL
  - `email`: VARCHAR(100), NOT NULL, UNIQUE (`customer_email_key`)
- **Indexes:** `customer_pkey` (BTREE PK), `customer_email_key` (BTREE UNIQUE)

#### 2. `habalgo.driver`
- **Primary Key:** `driver_id` (INTEGER, SERIAL sequence: `driver_driver_id_seq`)
- **Columns:**
  - `driver_id`: INTEGER, NOT NULL, DEFAULT `nextval('habalgo.driver_driver_id_seq'::regclass)`
  - `name`: VARCHAR(100), NOT NULL
  - `phone`: VARCHAR(20), NOT NULL
  - `license_no`: VARCHAR(50), NOT NULL, UNIQUE (`driver_license_no_key`)
- **Indexes:** `driver_pkey` (BTREE PK), `driver_license_no_key` (BTREE UNIQUE)

#### 3. `habalgo.vehicle`
- **Primary Key:** `vehicle_id` (INTEGER, SERIAL sequence: `vehicle_vehicle_id_seq`)
- **Columns:**
  - `vehicle_id`: INTEGER, NOT NULL, DEFAULT `nextval('habalgo.vehicle_vehicle_id_seq'::regclass)`
  - `plate_no`: VARCHAR(20), NOT NULL, UNIQUE (`vehicle_plate_no_key`)
  - `vehicle_type`: VARCHAR(50), NOT NULL
  - `model`: VARCHAR(50), NOT NULL
- **Indexes:** `vehicle_pkey` (BTREE PK), `vehicle_plate_no_key` (BTREE UNIQUE)

#### 4. `habalgo.driver_vehicle`
- **Primary Key:** Composite `(driver_id, vehicle_id)` (`driver_vehicle_pkey`)
- **Columns:**
  - `driver_id`: INTEGER, NOT NULL, FK -> `habalgo.driver(driver_id)` ON UPDATE CASCADE ON DELETE RESTRICT
  - `vehicle_id`: INTEGER, NOT NULL, FK -> `habalgo.vehicle(vehicle_id)` ON UPDATE CASCADE ON DELETE RESTRICT
  - `assigned_from`: TIMESTAMP WITHOUT TIME ZONE, NOT NULL
  - `assigned_to`: TIMESTAMP WITHOUT TIME ZONE, NULLABLE
- **Constraints:** `ck_assignment_dates` CHECK (`assigned_to IS NULL OR assigned_to >= assigned_from`)
- **Indexes:** `driver_vehicle_pkey` (BTREE PK)

#### 5. `habalgo.location`
- **Primary Key:** `location_id` (INTEGER, SERIAL sequence: `location_location_id_seq`)
- **Columns:**
  - `location_id`: INTEGER, NOT NULL, DEFAULT `nextval('habalgo.location_location_id_seq'::regclass)`
  - `address`: VARCHAR(255), NOT NULL
  - `city`: VARCHAR(100), NOT NULL
- **Indexes:** `location_pkey` (BTREE PK)

#### 6. `habalgo.booking`
- **Primary Key:** `booking_id` (INTEGER, SERIAL sequence: `booking_booking_id_seq`)
- **Columns:**
  - `booking_id`: INTEGER, NOT NULL, DEFAULT `nextval('habalgo.booking_booking_id_seq'::regclass)`
  - `customer_id`: INTEGER, NOT NULL, FK -> `habalgo.customer(customer_id)` ON UPDATE CASCADE ON DELETE RESTRICT
  - `driver_id`: INTEGER, NULLABLE, FK -> `habalgo.driver(driver_id)` ON UPDATE CASCADE ON DELETE SET NULL
  - `pickup_location_id`: INTEGER, NOT NULL, FK -> `habalgo.location(location_id)` ON UPDATE CASCADE ON DELETE RESTRICT
  - `dropoff_location_id`: INTEGER, NOT NULL, FK -> `habalgo.location(location_id)` ON UPDATE CASCADE ON DELETE RESTRICT
  - `booking_date`: TIMESTAMP WITHOUT TIME ZONE, NOT NULL, DEFAULT `CURRENT_TIMESTAMP`
  - `booking_status`: VARCHAR(50), NOT NULL, DEFAULT `'Pending'`
- **Constraints:** `ck_booking_status` CHECK (`booking_status IN ('Pending', 'Confirmed', 'In Progress', 'Completed', 'Cancelled')`)
- **Indexes:** 
  - `booking_pkey` (BTREE PK)
  - `idx_booking_customer` ON (`customer_id`)
  - `idx_booking_driver` ON (`driver_id`)
  - `idx_booking_date` ON (`booking_date`)

#### 7. `habalgo.payment`
- **Primary Key:** `payment_id` (INTEGER, SERIAL sequence: `payment_payment_id_seq`)
- **Columns:**
  - `payment_id`: INTEGER, NOT NULL, DEFAULT `nextval('habalgo.payment_payment_id_seq'::regclass)`
  - `booking_id`: INTEGER, NOT NULL, FK -> `habalgo.booking(booking_id)` ON UPDATE CASCADE ON DELETE RESTRICT
  - `amount`: NUMERIC(10,2), NOT NULL, CHECK (`amount > 0`)
  - `method`: VARCHAR(50), NOT NULL
  - `status`: VARCHAR(50), NOT NULL, DEFAULT `'Pending'`
- **Indexes:** `payment_pkey` (BTREE PK), `idx_payment_booking` ON (`booking_id`)

#### 8. `habalgo.rating_feedback`
- **Primary Key:** `rating_id` (INTEGER, SERIAL sequence: `rating_feedback_rating_id_seq`)
- **Columns:**
  - `rating_id`: INTEGER, NOT NULL, DEFAULT `nextval('habalgo.rating_feedback_rating_id_seq'::regclass)`
  - `booking_id`: INTEGER, NOT NULL, FK -> `habalgo.booking(booking_id)` ON UPDATE CASCADE ON DELETE RESTRICT
  - `customer_id`: INTEGER, NOT NULL, FK -> `habalgo.customer(customer_id)` ON UPDATE CASCADE ON DELETE RESTRICT
  - `rating`: INTEGER, NOT NULL, CHECK (`rating BETWEEN 1 AND 5`)
  - `feedback`: TEXT, NULLABLE
- **Constraints:** `uq_rating_booking_customer` UNIQUE (`booking_id, customer_id`)
- **Indexes:** `rating_feedback_pkey` (BTREE PK), `uq_rating_booking_customer` (BTREE UNIQUE), `idx_rating_booking` ON (`booking_id`)

---

## 5. Sequences, Views, and Triggers Audit

- **Sequences (7 Active):**
  1. `habalgo.customer_customer_id_seq`
  2. `habalgo.driver_driver_id_seq`
  3. `habalgo.vehicle_vehicle_id_seq`
  4. `habalgo.location_location_id_seq`
  5. `habalgo.booking_booking_id_seq`
  6. `habalgo.payment_payment_id_seq`
  7. `habalgo.rating_feedback_rating_id_seq`
- **Views:** None currently defined in schema `habalgo`.
- **Triggers:** None currently defined in schema `habalgo`. Business validation rules are enforced through declarative table check constraints and API transactions.

---

## 6. Access Control, Roles, and Privileges Audit

Inspection of cluster roles (`\du`) and object-level permissions (`\dp habalgo.*`) revealed the existing access control configuration established during Activity 4:

### Cluster Roles Identified
1. **`postgres`:** Superuser cluster administrator with all capabilities.
2. **`habalgo_admin`:** Administrative role with full privileges across all tables and sequences.
3. **`habalgo_app`:** Dedicated application runtime service role.
4. **`habalgo_auditor`:** Read-only analytical role.
5. **Group Roles (from `03_roles_and_privileges.sql`):** `app_runtime_grp`, `app_readonly_grp`, `app_admin_grp`.

### Table Privileges in Schema `habalgo`
| Role Name | Table Privileges (`habalgo.*`) | Sequence Privileges | Intended Role Scope |
| :--- | :--- | :--- | :--- |
| `postgres` | `arwdDxtm` (ALL) | `rwU` (ALL) | Database Cluster Administrator |
| `habalgo_admin` | `arwdDxtm` (ALL) | `rwU` (ALL) | HabalGo Application Administrator |
| `habalgo_app` | `arw` (SELECT, INSERT, UPDATE) | `rU` (USAGE, SELECT) | Web Backend / API Runtime Service Account |
| `habalgo_auditor` | `r` (SELECT only) | None | Auditor / Reporting Analyst |

*Legend: `a` = INSERT, `r` = SELECT, `w` = UPDATE, `d` = DELETE, `D` = TRUNCATE, `x` = REFERENCES, `t` = TRIGGER, `m` = MAINTAIN, `U` = USAGE.*

---

## 7. Current Data Population (Live Database vs. Script Artifacts)

A live count query executed against `grp00_habalgodb` on 2026-11-06 produced the following record counts:

| Table Name | Live Production Database Count | Available Seed Script Entries | Notes |
| :--- | :---: | :---: | :--- |
| `customer` | 0 | 2 (`database/02_seed.sql`) | Freshly initialized schema |
| `driver` | 0 | 10 (`sample data.sql`) | Freshly initialized schema |
| `vehicle` | 0 | 0 | Dynamic booking test data |
| `driver_vehicle` | 0 | 0 | Dynamic booking test data |
| `location` | 0 | 0 | Created dynamically by API |
| `booking` | 0 | 0 | Dynamic booking test data |
| `payment` | 0 | 0 | Dynamic billing test data |
| `rating_feedback` | 0 | 0 | Dynamic rating test data |

> [!IMPORTANT]
> In strict compliance with **Safety Rule 3** (*Never initialize or reseed the original database*) and **Safety Rule 4** (*Never delete genuine application records*), the live production database `grp00_habalgodb` must remain unaltered during baseline inspection. All testing, sample data injection, and recovery simulations will occur strictly within isolated test databases.

---

## 8. Backup Compatibility Assessment

- **Engine Match:** Compatible. HabalGo strictly utilizes PostgreSQL 18.6, matching the COMP 018 Activity 6 specification.
- **Backup Tool:** PostgreSQL `pg_dump` with Custom Archive format (`-Fc`).
- **Restoration Tool:** PostgreSQL `pg_restore` and `createdb`.
- **Pre-backup Status:** Verification complete. Proceeding to Phase 2 (Backup Planning).

