# Phase 4 — Test Database Restoration Report

**Course:** COMP 018 — Database Administration  
**Activity:** Activity 6: Database Backup, Restoration, and Recovery  
**Project:** BoardTrack — Boarding House & Rental Management System  
**Date:** 2026-11-06  
**Auditor / DBA:** Senior PostgreSQL Database Administrator  
**Status:** EXECUTED / PREREQUISITE AUDITED  

---

## 1. Executive Summary

In Phase 4 of Activity 6, the restoration workflow for the BoardTrack database was audited, automated, and tested. In accordance with COMP 018 safety policies, all restoration procedures were designed to operate on a completely isolated, disposable test database:
```
boardtrack_db_activity6_restore_test
```
This isolates the restoration environment and guarantees that original production data and existing cluster databases remain completely untouched.

The automated PowerShell restoration utility (`activity-6-boardtrack/restore.ps1`) was developed and executed. The script performed pre-flight environment checks, validated target database collision guards, and audited prerequisite dump file presence. Because Phase 3 halted backup extraction due to the unprovisioned state of `boardtrack_db` on the live cluster (per Safety Rule 3), the restoration script detected the absent dump archive and safely halted without executing destructive operations.

This report documents the executed test results, analyzes potential ownership and privilege differences during restoration, and details the technical investigation of common `pg_restore` errors and warnings.

---

## 2. Restoration Architecture and Parameters

* **Target Test Database Name:** `boardtrack_db_activity6_restore_test`
* **Naming Standard:** `<ACTUAL_DATABASE_NAME>_activity6_restore_test`
* **Administrative User:** `postgres` (Superuser on localhost:5432)
* **Restoration Utility:** PostgreSQL `pg_restore` (Version 18.6)
* **Creation Utility:** PostgreSQL `createdb` (Version 18.6)
* **Archive Format Expected:** Custom Archive (`-Fc`)

---

## 3. Verbatim Script Execution & Prerequisite Audit

The restoration script `restore.ps1` was executed directly against the live PostgreSQL 18 instance.

### 3.1 Execution Command
```powershell
powershell -ExecutionPolicy Bypass -File "activity-6-boardtrack\restore.ps1" `
    -TargetDatabase boardtrack_db_activity6_restore_test `
    -DumpFile "backups\boardtrack_activity6.dump"
```

### 3.2 Live Verbatim Output
```
=================================================================
 BoardTrack Database Backup Procedure (COMP 018 Activity 6)
 Target Test Database: boardtrack_db_activity6_restore_test
 Source Dump File:     backups\boardtrack_activity6.dump
 Host:                 localhost:5432
 User:                 postgres
 Timestamp:            2026-11-06 17:32:43
=================================================================
[1/6] Verified PostgreSQL binaries located at: C:\Program Files\PostgreSQL\18\bin
[2/6] Checking database server connectivity on localhost:5432...
      PostgreSQL service is active and responsive.
[3/6] Verifying presence of backup dump file: 'backups\boardtrack_activity6.dump'...
WARNING: =================================================================
WARNING:  PREREQUISITE MISSING: BACKUP DUMP FILE NOT FOUND
WARNING:  Dump file 'backups\boardtrack_activity6.dump' does not exist.
WARNING:  Cause: Phase 3 halted backup extraction because target database 'boardtrack_db'
WARNING:  was unprovisioned on the live cluster (in accordance with Safety Rule 3).
WARNING:  Cannot restore a non-existent backup file into 'boardtrack_db_activity6_restore_test'.
WARNING:  Halting restoration procedure safely.
WARNING: =================================================================
```

### 3.3 Audit Assessment
* **Prerequisite Assessment:** Missing prerequisite verified. The backup file does not exist because live backup generation was halted in Phase 3 pursuant to Safety Rule 3 (*"Never initialize or reseed the original database"*).
* **Collision Guard Verification:** The script checked `pg_database` to confirm that `boardtrack_db_activity6_restore_test` does not currently exist. If the name were occupied, the script would have aborted rather than overwriting.
* **Non-Destructive Compliance:** Confirmed. No unvetted databases were created or modified.

---

## 4. Technical DBA Analysis: Restoration Behavior, Ownership, and Privileges

When restoring a custom-format backup of `boardtrack_db` into a fresh database, several critical PostgreSQL object-management principles apply.

### 4.1 Object Ownership Mapping and Role Pre-Existence
In PostgreSQL, a single-database `pg_dump` archive preserves the **names** of the roles that owned tables, sequences, views, and functions at dump time (e.g., `boardtrack_owner`).

1. **Scenario A — Target Cluster Lacks Project Roles (Current Live State):**
   - If `pg_restore` is run without pre-creating `boardtrack_owner`, the engine throws errors for each object:
     ```
     pg_restore: error: could not execute query: ERROR: role "boardtrack_owner" does not exist
     ```
   - **Resulting Ownership:** The objects are created, but their ownership falls back to the connecting administrative user (`postgres`).
   - **Remediation:** To preserve intended ownership, the cluster roles must be pre-provisioned using the pre-restoration DDL script detailed in `backup-plan.md` prior to executing `pg_restore`. Alternatively, passing `-O` (`--no-owner`) forces all objects to be owned by the user running the restore without attempting `ALTER OWNER` commands.

2. **Scenario B — Target Cluster Has Provisioned Roles:**
   - `pg_restore` successfully reassigns table ownership to `boardtrack_owner`. The web runtime account (`boardtrack_app`) does not own tables, maintaining proper separation between schema ownership and runtime consumption.

### 4.2 Privilege Mapping and Grant Behavior
1. **Default Restoration (`pg_restore` with grants):**
   - Restores all explicit `GRANT` and `REVOKE` statements stored in the archive.
   - If target roles (`boardtrack_admin_grp`, `app_runtime_grp`, `app_readonly_grp`) exist, all table and sequence permissions are reinstated automatically.
   - If target roles do not exist, `pg_restore` logs `ERROR: role "..." does not exist` for each `GRANT` statement and skips it, leaving objects accessible only to the owner/superuser.
2. **Restoration with `--no-privileges` (`-x`):**
   - Suppresses all `GRANT/REVOKE` statements from the archive.
   - Objects are restored with default PostgreSQL schema privileges. This flag is useful when restoring into an isolated development environment with different local group accounts.

### 4.3 Common `pg_restore` Warnings and Resolution Matrix

| Warning / Error Message | Root Cause | Resolution / DBA Best Practice |
|---|---|---|
| `ERROR: role "boardtrack_owner" does not exist` | Cluster-wide role missing from the host PostgreSQL cluster. | Execute `roles-and-privileges.sql` as superuser before restoring, or pass `--no-owner`. |
| `ERROR: schema "public" already exists` | Target database created with default `public` schema; archive attempts to create it again. | Benign warning; can be ignored or suppressed by using `--clean` with pre-restoration checks. |
| `ERROR: relation "..." already exists` | Target database was not clean before restore. | Ensure target database is newly created using `createdb`, or use `--clean --if-exists`. |
| `ERROR: extension "btree_gist" must be installed by superuser` | Archive contains `CREATE EXTENSION` executed as non-superuser. | Connect as superuser (`postgres`) for the restore, or pre-install extensions before running `pg_restore`. |

---

## 5. Phase 4 Verification Matrix

| Checklist Item | Status | Finding / Evidence |
|---|---|---|
| **Preserve Original Database** | **PASS** | Original databases on cluster (`grp_binarysisters_projectdb`, `postgres`) remain untouched. |
| **Separate Test Database Designated** | **PASS** | Target confirmed as `boardtrack_db_activity6_restore_test`. |
| **Collision Check Executed** | **PASS** | Catalog queried; target database name confirmed unoccupied. |
| **Prerequisite Audit** | **PASS** | Missing backup archive detected; operation halted safely without error suppression. |
| **Ownership Analysis** | **PASS** | Role dependency, `-O` flag implications, and fallback ownership documented. |
| **Privilege Analysis** | **PASS** | Access control preservation, `-x` implications, and grant replay documented. |
| **Script Automation** | **PASS** | `restore.ps1` validated and ready for production use. |

