# Phase 1: Comprehensive Project and Database Inspection Report

**Project:** Campus Canteen Pre-Order and Queue Management System  
**Organization / Group:** BWIS IT Solutions  
**Repository:** `https://github.com/EclipseChan/bwisIT-Solutions---Campus-Canteen-Pre-Order-and-Queue-Management-System.git`  
**Inspection Date:** 2026-11-06  
**Auditor:** Senior PostgreSQL Database Administrator & Software Engineer (COMP 018)  

---

## 1. Project Technology Stack Overview

| Component | Verified Technology | Version / Configuration | Evidence File Reference |
|---|---|---|---|
| **Database Engine** | PostgreSQL | PostgreSQL 18.6 on x86_64-windows | `SELECT version();` / `pom.xml` line 34 |
| **Database Name** | `canteendb` | Configured as `canteen_db` in `.env.example` | `\l` catalog query / `application.properties` |
| **Backend Framework** | Java / Spring Boot | Spring Boot 3.4.1 (Java 21) | `pom.xml` lines 8-15 |
| **ORM / Persistence** | Spring Data JPA / Hibernate | Hibernate 6.x (`ddl-auto=validate`) | `src/main/resources/application.properties` |
| **Security Framework** | Spring Security + JJWT | io.jsonwebtoken 0.12.6, BCrypt password hashing | `pom.xml` lines 42-63 |
| **Frontend Framework** | React + Vite | React 18.3.1, Vite 5.4.11 | `frontend/package.json` lines 6-8 |
| **Database Host & Port**| Localhost TCP/IP | `127.0.0.1:5432` | `.env.example` / `pg_env.bat` |
| **Connection Method** | JDBC & psql CLI | `jdbc:postgresql://localhost:5432/canteendb` | `application.properties` line 4 |

---

## 2. In-Depth Database Schema & Entity Inspection

Inspection of the actual database catalog (`information_schema` and `pg_catalog`) confirms that the database contains **7 relational application tables** and **7 associated serial sequences** in the `public` schema.

### 2.1 Table Specifications and Column Definitions

#### Table: `public.student`
Stores customer accounts (students and canteen administrators).
- `student_id` (`integer`, NOT NULL, Default: `nextval('student_student_id_seq'::regclass)`) - Primary Key
- `full_name` (`varchar(100)`, NOT NULL)
- `email` (`varchar(150)`, NOT NULL, UNIQUE)
- `password_hash` (`varchar(255)`, NOT NULL) - BCrypt encoded credential
- `created_at` (`timestamp without time zone`, NOT NULL, Default: `now()`)
- `role` (`varchar(20)`, NOT NULL, Default: `'STUDENT'`, CHECK: `role IN ('STUDENT', 'ADMIN')`)

#### Table: `public.vendor`
Stores canteen stalls/concessionaires.
- `vendor_id` (`integer`, NOT NULL, Default: `nextval('vendor_vendor_id_seq'::regclass)`) - Primary Key
- `vendor_name` (`varchar(100)`, NOT NULL)
- `contact_number` (`varchar(20)`, Nullable)
- `is_active` (`boolean`, NOT NULL, Default: `true`)
- `email` (`varchar(150)`, Nullable, UNIQUE) - Concessionaire login identity
- `password_hash` (`varchar(255)`, Nullable) - BCrypt credential

#### Table: `public.menu_item`
Stores food and beverage offerings sold by vendors.
- `item_id` (`integer`, NOT NULL, Default: `nextval('menu_item_item_id_seq'::regclass)`) - Primary Key
- `vendor_id` (`integer`, NOT NULL, FK to `vendor(vendor_id)`)
- `item_name` (`varchar(100)`, NOT NULL)
- `price` (`numeric`, NOT NULL, CHECK: `price >= 0`)
- `is_available` (`boolean`, NOT NULL, Default: `true`)

#### Table: `public.customer_order`
Stores food pre-orders placed by students.
- `order_id` (`integer`, NOT NULL, Default: `nextval('customer_order_order_id_seq'::regclass)`) - Primary Key
- `student_id` (`integer`, NOT NULL, FK to `student(student_id)`)
- `vendor_id` (`integer`, NOT NULL, FK to `vendor(vendor_id)`)
- `order_date` (`timestamp without time zone`, NOT NULL, Default: `now()`)
- `pickup_time` (`time without time zone`, NOT NULL)
- `status` (`varchar(20)`, NOT NULL, Default: `'pending'`, CHECK: `status IN ('pending', 'preparing', 'ready', 'completed', 'cancelled')`)

#### Table: `public.order_item`
Stores order line items linking pre-orders with specific menu items.
- `order_item_id` (`integer`, NOT NULL, Default: `nextval('order_item_order_item_id_seq'::regclass)`) - Primary Key
- `order_id` (`integer`, NOT NULL, FK to `customer_order(order_id)`)
- `item_id` (`integer`, NOT NULL, FK to `menu_item(item_id)`)
- `quantity` (`integer`, NOT NULL, CHECK: `quantity > 0`)
- `price_at_order` (`numeric`, NOT NULL) - Historical pricing snapshot

#### Table: `public.queue_entry`
Stores daily queue positions and tokens assigned to pre-orders.
- `queue_id` (`integer`, NOT NULL, Default: `nextval('queue_entry_queue_id_seq'::regclass)`) - Primary Key
- `order_id` (`integer`, NOT NULL, UNIQUE, FK to `customer_order(order_id)`)
- `queue_number` (`integer`, NOT NULL)
- `queue_date` (`date`, NOT NULL, Default: `CURRENT_DATE`)
- `status` (`varchar(20)`, NOT NULL, Default: `'waiting'`, CHECK: `status IN ('waiting', 'called', 'served')`)
- **Compound Unique:** `UNIQUE (queue_number, queue_date)`

#### Table: `public.notification`
Stores automated status notifications sent to students.
- `notification_id` (`integer`, NOT NULL, Default: `nextval('notification_notification_id_seq'::regclass)`) - Primary Key
- `order_id` (`integer`, NOT NULL, FK to `customer_order(order_id)`)
- `message` (`text`, NOT NULL)
- `sent_at` (`timestamp without time zone`, NOT NULL, Default: `now()`)
- `is_read` (`boolean`, NOT NULL, Default: `false`)

---

## 3. Database Constraints and Indexes Inventory

### 3.1 Primary Keys (7)
1. `student_pkey` on `student(student_id)`
2. `vendor_pkey` on `vendor(vendor_id)`
3. `menu_item_pkey` on `menu_item(item_id)`
4. `customer_order_pkey` on `customer_order(order_id)`
5. `order_item_pkey` on `order_item(order_item_id)`
6. `queue_entry_pkey` on `queue_entry(queue_id)`
7. `notification_pkey` on `notification(notification_id)`

### 3.2 Foreign Keys and Referential Integrity (7)
1. `menu_item_vendor_id_fkey`: `menu_item(vendor_id)` REFERENCES `vendor(vendor_id)`
2. `customer_order_student_id_fkey`: `customer_order(student_id)` REFERENCES `student(student_id)`
3. `customer_order_vendor_id_fkey`: `customer_order(vendor_id)` REFERENCES `vendor(vendor_id)`
4. `order_item_order_id_fkey`: `order_item(order_id)` REFERENCES `customer_order(order_id)`
5. `order_item_item_id_fkey`: `order_item(item_id)` REFERENCES `menu_item(item_id)`
6. `queue_entry_order_id_fkey`: `queue_entry(order_id)` REFERENCES `customer_order(order_id)`
7. `notification_order_id_fkey`: `notification(order_id)` REFERENCES `customer_order(order_id)`

### 3.3 Unique Constraints (4)
1. `student_email_key`: `UNIQUE (email)` on `student`
2. `vendor_email_key`: `UNIQUE (email)` on `vendor`
3. `queue_entry_order_id_key`: `UNIQUE (order_id)` on `queue_entry` (guarantees exactly one queue token per order)
4. `queue_entry_queue_number_queue_date_key`: `UNIQUE (queue_number, queue_date)` on `queue_entry` (resets queue token counter daily)

### 3.4 Check Constraints (7)
1. `student_role_check`: `CHECK (role IN ('STUDENT', 'ADMIN'))`
2. `menu_item_price_check`: `CHECK (price >= 0)`
3. `customer_order_status_check`: `CHECK (status IN ('pending', 'preparing', 'ready', 'completed', 'cancelled'))`
4. `order_item_quantity_check`: `CHECK (quantity > 0)`
5. `queue_entry_status_check`: `CHECK (status IN ('waiting', 'called', 'served'))`
6. `student` created_at, email, full_name, password_hash NOT NULL checks
7. `customer_order` pickup_time, status, order_date NOT NULL checks

### 3.5 Indexes (11 B-Tree Indexes)
PostgreSQL automatically generates B-tree indexes for all 7 Primary Keys and 4 Unique Constraints:
- `student_pkey`, `student_email_key`
- `vendor_pkey`, `vendor_email_key`
- `menu_item_pkey`
- `customer_order_pkey`
- `order_item_pkey`
- `queue_entry_pkey`, `queue_entry_order_id_key`, `queue_entry_queue_number_queue_date_key`
- `notification_pkey`

### 3.6 Views and Triggers
- **Views:** 0 user-defined views exist in the schema.
- **Triggers:** 0 user-defined triggers exist. (Foreign key constraints internally utilize 28 PostgreSQL system RI constraint triggers for referential enforcement).

---

## 4. Roles and Privileges Inspection

### 4.1 Cluster PostgreSQL Roles
- `postgres`: Superuser account used for cluster administration.
- `canteen_admin`: Object owner account (`LOGIN`, `CREATEROLE`, `NOCREATEDB`, `NOSUPERUSER`).
- `canteen_app`: Application runtime login account (`LOGIN`, `NOCREATEROLE`, `NOCREATEDB`, `NOSUPERUSER`).
- `canteen_readonly`: Reporting login account (`LOGIN`, `NOCREATEROLE`, `NOCREATEDB`, `NOSUPERUSER`).
- `canteen_app_grp`: NOLOGIN privilege group for application DML operations.
- `canteen_readonly_grp`: NOLOGIN privilege group for reporting `SELECT` operations.

### 4.2 Application Roles (JWT Security)
- `STUDENT`: End-user student customer; can browse menu, place orders, cancel pending orders, view personal notifications.
- `VENDOR`: Canteen stall owner; can manage own menu items, update incoming order progress, view stall sales reports.
- `ADMIN`: Campus canteen manager (a student row with `role = 'ADMIN'`); can activate/deactivate vendor stalls, monitor all queues, and access canteen-wide sales analytics.
- Public: Unauthenticated visitor; can browse active vendor stalls and view available menu offerings.

---

## 5. Existing Seed Data and Live Database State

- **Seed Dataset (`database/seed/001_sample_data.sql`):** Contains demo student accounts (`admin@canteen.test`, `maria@student.test`, `juan@student.test`), 4 food stalls (Aling Nena's, Kuya Jun's, Merienda Corner, Waffle Corner), 10 menu items, and 2 sample pre-orders.
- **Live Database Inspection (`canteendb`):** Currently holds **0 records** across all 7 tables (fresh schema state following migration). In accordance with the activity safety rules, the original database `canteendb` was left untouched and was not initialized or reseeded.

---

## 6. Compatibility Statement

- **PostgreSQL Compatibility:** **100% Fully Compatible.** The repository natively uses PostgreSQL (DDL scripts in `database/`, Spring PostgreSQL JDBC driver, and PostgreSQL-specific syntax such as `\gexec`, `SERIAL`, and `row_to_json`).
- No foreign engines (MySQL, SQLite, MongoDB) are used.

