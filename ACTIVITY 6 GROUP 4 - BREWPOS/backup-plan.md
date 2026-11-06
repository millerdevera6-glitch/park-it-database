# BrewPOS PostgreSQL Backup and Recovery Plan

## 1. Database Information

- Project: BrewPOS
- Database: grp_brewposdb
- Database owner: postgres
- PostgreSQL version used for testing: 14.24
- Backup date: November 6, 2026
- Backup administrator: Local PostgreSQL administrator

## 2. Backup Scope and Method

The backup covers the BrewPOS database, including:
- Five database tables and their records
- Four sequences and their current values
- Primary keys, foreign keys, unique constraints, and check constraints
- Indexes and default values
- Database objects and associated metadata included in the archive

A PostgreSQL custom-format backup was created using pg_dump with the -Fc option.

Backup file:
grp_brewposdb_2026-11-06.dump

Protected local backup location:
C:\DB_Backups\BrewPOS

The backup file is kept outside the application repository to prevent accidental publication.

## 3. Backup Verification

The backup was verified using:
- pg_restore --list to inspect the archive contents
- File size verification
- SHA-256 checksum verification using Get-FileHash

The archive inspection completed successfully and reported 55 TOC entries.

## 4. Backup Schedule and Retention

Proposed backup schedule:
- Daily full database backup
- Weekly verification of backup archives
- Periodic restoration test in a separate database

Proposed retention:
- Seven daily backup copies
- Four weekly backup copies

The current exercise produced one local backup archive. The schedule and retention policy are recommendations and are not yet automated.

## 5. Backup Security

- Store backups outside the application repository.
- Restrict access to authorized database administrators.
- Do not include database passwords or credentials in scripts, reports, or Git commits.
- Maintain an additional protected copy in a separate storage location as a future improvement.

## 6. Roles and Privileges

PostgreSQL login roles and memberships are cluster-level objects and are not recreated by an ordinary per-database pg_dump restore.

The BrewPOS application role is:
brewpos_app

The role must be recreated or verified separately when recovering to another PostgreSQL cluster. Its database-specific privileges and settings must also be reapplied and verified.

The restore test used --no-owner and --no-acl. Application privileges were therefore explicitly reapplied to the restored database and verified through an actual application-role login.

## 7. Recovery Objectives

Proposed Recovery Point Objective (RPO): 24 hours.

This target assumes that a daily backup is completed successfully. Data changes made after the latest backup may need to be recreated.

Proposed Recovery Time Objective (RTO): 2 hours.

This is a planning target for restoring this small database and validating its important objects and access permissions. It is not a measured service guarantee.

## 8. Recovery Procedure

1. Confirm that the backup archive is available and its checksum matches the recorded value.
2. Create a new, empty recovery database.
3. Restore the archive using pg_restore.
4. Verify tables, records, sequences, constraints, and indexes.
5. Recreate or verify required PostgreSQL roles and memberships.
6. Reapply database privileges and role-specific settings.
7. Test allowed and denied operations using the application login.
8. Confirm that the application can access the recovered database.

All restoration tests must use a separate database. The original database and backup archive must remain unchanged.
