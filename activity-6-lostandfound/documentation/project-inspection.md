# Technical Inspection Report — PUP-SPOT Architecture & Live Database Audit
## Project: PUP-SPOT — Campus Lost and Found System
**Course:** COMP 018 — Database Administration | Activity 6  
**Auditor:** Senior Database Administrator & Technical Documentation Specialist  
**Audit Date:** November 6, 2026  
**Primary Database:** `grp05_lostandfounddb` (PostgreSQL 18.6 on Windows x64)

---

## 1. Executive Summary

This inspection report documents the architectural, schema, access control, and codebase evaluation of the **PUP-SPOT Campus Lost and Found System** repository (`https://github.com/grp05-dba/grp05_lostandfound.git`). The audit involved reviewing all source code files, database definitions, deployment documentation, and conducting a live catalog inspection against the local PostgreSQL 18.6 database instance.

---

## 2. Codebase & Directory Structure Analysis

The repository is structured to separate administrative features from public student self-service:

```text
grp05_lostandfound/
├── .env.example              # Environment variables template
├── .gitignore                # Git exclusions (credentials, uploads, dumps)
├── README.md                 # System setup guide and deployment documentation
├── admin/                    # Admin portal web files
│   ├── app.html              # Single-page administrative dashboard
│   ├── css/admin.css         # Admin stylesheet
│   ├── index.php             # Admin API entry point (calls Connection::getAdminConnection)
│   └── js/admin.js           # Admin UI state logic and API calls
├── docs/                     # Technical specifications and system architecture
│   ├── api.md                # REST API endpoint reference
│   ├── architecture.md       # Tiered system architecture & component breakdown
│   ├── branch-workflow.md    # Development Git branch conventions
│   ├── database.md           # Database design notes and entity descriptions
│   ├── development-history.md# Milestones and changelog
│   ├── repository-review.md  # Comprehensive architectural critique
│   ├── setup.md              # Detailed local environment setup notes
│   └── user-roles.md         # Network isolation & RBAC model documentation
├── public/                   # Public student/guest interface
│   ├── app.html              # Public search, reporting, and claim interface
│   ├── css/app.css           # Public stylesheet
│   ├── index.php             # Public API entry point (calls Connection::getPublicConnection)
│   ├── js/app.js             # Client interface handling
│   └── js/potentialMatching.js # Client-side match scoring utilities
├── sql/                      # Authoritative SQL scripts
│   ├── grp05_lostandfounddb_script.sql               # Authoritative schema DDL
│   ├── grp05_lostandfounddb_necessary_data_script.sql# Mandatory category seed DML
│   ├── grp05_lostandfounddb_role_creation_sample_script.sql # RBAC grants
│   └── grp05_lostandfounddb_demo_data_script.sql     # Idempotent demo records
├── src/                      # PHP Backend Core (24 modular class files)
│   ├── db/db.php             # PDO Connection factory (Public & Admin connections)
│   ├── entities/             # Item, LostReport, Claim entities
│   ├── repositories/         # Category, Item, LostReport, Claim, Image, PotentialMatch
│   ├── services/             # Item, LostReport, Claim, Match, Image, Search, SMS, Email
│   ├── integrations/         # TextBee (SMS) and EmailJS (Email) HTTP clients
│   └── utils/requestUtils.php# Request normalization and field validators
└── storage/                  # Uploaded image binary filesystem storage
    ├── claims/               # Claimant proof images (.gitkeep preserved)
    ├── items/                # Found item photos (.gitkeep preserved)
    └── lost-reports/         # Lost item proof photos (.gitkeep preserved)
```

---

## 3. Database Schema: Repository Definitions vs Live Database

A comparison was performed between `sql/grp05_lostandfounddb_script.sql` and the live PostgreSQL catalog (`information_schema.columns`, `information_schema.table_constraints`, `pg_indexes`, and `pg_sequences`).

### Table & Column Comparison Matrix

| Table Name | Live Columns & Types | Primary Key | Foreign Keys (Live Action) | Unique & Check Constraints |
| :--- | :--- | :--- | :--- | :--- |
| `categories` | `category_id` (INT / SERIAL)<br>`name` (VARCHAR(100)) | `category_id` | *None* | `name` NOT NULL |
| `items` | `item_id` (INT / SERIAL)<br>`category_id` (INT)<br>`title` (VARCHAR(255))<br>`description` (TEXT)<br>`location_found` (VARCHAR(255))<br>`date_found` (DATE)<br>`time_found` (TIME)<br>`status` (VARCHAR(50)) | `item_id` | `category_id` → `categories.category_id`<br>(`ON DELETE SET NULL`) | `status IN ('unclaimed', 'claimed', 'archived')`<br>`title` NOT NULL |
| `lost_reports` | `report_id` (INT / SERIAL)<br>`report_code` (VARCHAR(50))<br>`category_id` (INT)<br>`title` (VARCHAR(255))<br>`description` (TEXT)<br>`location_lost` (VARCHAR(255))<br>`date_lost` (DATE)<br>`time_lost` (TIME)<br>`full_name` (VARCHAR(150))<br>`student_number` (VARCHAR(50))<br>`email` (VARCHAR(150))<br>`phone_number` (VARCHAR(50))<br>`contact_preference` (VARCHAR(10))<br>`status` (VARCHAR(50))<br>`created_at` (TIMESTAMP) | `report_id` | `category_id` → `categories.category_id`<br>(`ON DELETE SET NULL`) | `report_code` UNIQUE<br>`status IN ('active', 'resolved', 'cancelled')`<br>`contact_preference IN ('email', 'sms')`<br>`chk_lost_reports_contact`:<br>`(email IS NOT NULL OR phone_number IS NOT NULL)` |
| `claims` | `claim_id` (INT / SERIAL)<br>`claim_code` (VARCHAR(50))<br>`item_id` (INT)<br>`full_name` (VARCHAR(150))<br>`student_number` (VARCHAR(50))<br>`email` (VARCHAR(150))<br>`phone_number` (VARCHAR(50))<br>`contact_preference` (VARCHAR(10))<br>`status` (VARCHAR(50))<br>`created_at` (TIMESTAMP) | `claim_id` | `item_id` → `items.item_id`<br>(`ON DELETE CASCADE`) | `claim_code` UNIQUE<br>`status IN ('pending', 'approved', 'rejected')`<br>`contact_preference IN ('email', 'sms')`<br>`chk_claims_contact`:<br>`(email IS NOT NULL OR phone_number IS NOT NULL)` |
| `potential_matches`| `match_id` (INT / SERIAL)<br>`report_id` (INT)<br>`item_id` (INT)<br>`similarity_score` (NUMERIC(5,2))<br>`created_at` (TIMESTAMP) | `match_id` | `report_id` → `lost_reports.report_id`<br>(`ON DELETE CASCADE`)<br>`item_id` → `items.item_id`<br>(`ON DELETE CASCADE`) | `similarity_score >= 0 AND similarity_score <= 100` |
| `item_images` | `item_image_id` (INT / SERIAL)<br>`item_id` (INT)<br>`storage_key` (VARCHAR(100))<br>`mime_type` (VARCHAR(50))<br>`created_at` (TIMESTAMP) | `item_image_id` | `item_id` → `items.item_id`<br>(`ON DELETE CASCADE`) | `storage_key`, `mime_type` NOT NULL |
| `lost_report_images`| `report_image_id` (INT / SERIAL)<br>`report_id` (INT)<br>`storage_key` (VARCHAR(100))<br>`mime_type` (VARCHAR(50))<br>`created_at` (TIMESTAMP) | `report_image_id` | `report_id` → `lost_reports.report_id`<br>(`ON DELETE CASCADE`) | `storage_key`, `mime_type` NOT NULL |
| `claim_images` | `claim_image_id` (INT / SERIAL)<br>`claim_id` (INT)<br>`storage_key` (VARCHAR(100))<br>`mime_type` (VARCHAR(50))<br>`created_at` (TIMESTAMP) | `claim_image_id` | `claim_id` → `claims.claim_id`<br>(`ON DELETE CASCADE`) | `storage_key`, `mime_type` NOT NULL |

---

## 4. Live Data State Audit

Querying the live database `grp05_lostandfounddb` yielded the following verified row counts:

| Table | Live Row Count | Source / Record Classification |
| :--- | :---: | :--- |
| `categories` | **11** | Mandatory categories (`IDs and Documents`, `Wallets`, `Gadgets`, etc.) |
| `items` | **6** | 1 test item ('Unauthorized Update') + 5 demo records (`[DEMO] ...`) |
| `lost_reports` | **7** | Demonstration lost reports (`DEMO-LR-001` through `DEMO-LR-007`) |
| `claims` | **3** | Demonstration claims (`DEMO-CLM-001`, `DEMO-CLM-002`, `DEMO-CLM-003`) |
| `potential_matches`| **6** | Calculated demonstration match scores (61.25% to 99.00%) |
| `item_images` | **0** | No live image records |
| `lost_report_images`| **0** | No live image records |
| `claim_images` | **0** | No live image records |
| **Total Rows** | **33** | Clean operational testbed |

---

## 5. PostgreSQL Roles and Security Audit

Inspection of `pg_roles` revealed:
- `postgres`: Superuser, login-enabled, owner of all database objects in `public`.
- `lostandfound_app`: Non-superuser, login-enabled, admin application role.
- `lostandfound_public`: Non-superuser, login-enabled, restricted public portal role.

### Critical Finding: Code Connection Correction
In early documentation (`docs/api.md` line 76 and `docs/repository-review.md`), it was flagged that `public/index.php` mistakenly called `getAdminConnection()`. Inspection of the current codebase revealed that line 35 of `public/index.php` properly calls `Connection::getPublicConnection()`, and `admin/index.php` calls `Connection::getAdminConnection()`. The architectural privilege isolation is properly maintained in the active PHP code.

---

## 6. Pre-existing Backup Procedures Audit

The repository contained **no pre-existing automated backup or disaster recovery scripts** prior to Activity 6. The only data-repopulation mechanism was `sql/grp05_lostandfounddb_demo_data_script.sql`, which deletes and re-inserts demo rows rather than acting as a point-in-time recovery mechanism. Implementing Activity 6 provides the PUP-SPOT project with its first enterprise-grade backup and recovery infrastructure.

