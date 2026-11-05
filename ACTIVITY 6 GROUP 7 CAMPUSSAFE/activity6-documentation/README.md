# Activity 6 – CampusSafe Backup and Recovery

## Project Information
- **Project:** CampusSafe – Campus Hazard & Safety Reporting System
- **Project Group:** Group 7
- **Evaluating Group:** Group 2
- **Database:** `grp07_campussafedb`
- **DBMS:** PostgreSQL 14

## Activity 6 Accomplishments

1. Created a logical database backup using PostgreSQL `pg_dump` in custom format (`-Fc`).
2. Inspected the backup archive using `pg_restore --list`.
3. Restored the backup into a separate test database named `grp07_campussafedb_restore_test`.
4. Verified all nine restored tables, selected record counts, and database constraints.
5. Checked the presence of Activity 4 roles, role memberships, and table permissions.
6. Tested reporting access using `campussafe_report`.
7. Confirmed that the reporting account could read hazard reports but could not update them.
8. Performed a separate recovery test using `grp07_campussafedb_recovery_test`.

## Important Files
- `backup-plan.md` – Backup strategy and recovery objectives.
- `backup-commands.md` – Backup creation and archive inspection details.
- `restore-verification.sql` – SQL verification queries.
- `recovery-simulation.md` – Recovery procedure and results.
- `evidence/` – Screenshots documenting backup, restoration, verification, and recovery.

## Backup Storage
The actual backup file is stored outside the Git repository in a protected local folder:

`C:\xampp\htdocs\jquery-fileupload-sessions\activity6_backups\`

**Do not commit the actual `.dump` backup file or database passwords to GitHub.**

## Overall Result
The backup was successfully created and inspected. Restoration and separate recovery tests completed without reported errors. The restored database retained its tables, selected records, constraints, and tested Activity 4 permissions.