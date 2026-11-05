# Activity 6 – Backup Plan

## 1. Project Information

- **Project:** CampusSafe – Campus Hazard & Safety Reporting System
- **Evaluated Group:** Group 7
- **Evaluating Group:** Group 2
- **Database Name:** `grp07_campussafedb`
- **Database Management System:** PostgreSQL

## 2. Database Objects to Back Up

The backup will include all database objects and data, including:

- Tables and records
- Primary keys and foreign keys
- Constraints and indexes
- Sequences
- Views
- Functions and triggers, if present
- Other database objects included in the logical database dump

## 3. Backup Method

The selected method is PostgreSQL `pg_dump` using the custom archive format (`-Fc`).

This method is appropriate because it creates a logical backup that can be inspected using `pg_restore --list` and restored using `pg_restore`.

## 4. Backup Storage and Access

The backup file will be stored in a protected local folder outside the GitHub repository.

Only authorized database administrators and personnel assigned to backup and recovery tasks should have access to the backup file.

The backup file will not be committed or uploaded to GitHub because it contains database information.

## 5. Backup Verification

The backup will be checked using:

- File existence and file size
- SHA-256 checksum
- PostgreSQL `pg_restore --list`
- Restoration into a separate test database

A successful restoration will provide stronger evidence that the backup is usable.

## 6. Proposed Backup Schedule and Retention

For a real deployment, the proposed schedule is:

- Daily database backup.
- Weekly backup retained for one month.
- Monthly backup retained for six months.
- Old backups securely deleted according to the retention policy.

## 7. Recovery Objectives

**Recovery Point Objective (RPO):** 24 hours. The system should not lose more than one day's worth of data.

**Recovery Time Objective (RTO):** 4 hours. The system should be restored and operational within four hours after