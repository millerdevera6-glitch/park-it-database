# Activity 6 – Backup Creation and Inspection

## 1. Backup Information

- **Project:** CampusSafe
- **Group:** Group 7
- **Database:** `grp07_campussafedb`
- **Backup Date:** November 5, 2026
- **Backup Format:** PostgreSQL Custom Archive (`-Fc`)
- **Backup Account:** `campussafe_backup`

## 2. Backup Command

```powershell
pg_dump -U campussafe_backup -h localhost -p 5432 -Fc -d grp07_campussafedb -f "C:\xampp\htdocs\jquery-fileupload-sessions\activity6_backups\grp07_campussafedb_activity6.dump"
```

## 3. Backup File Details

- **Filename:** `grp07_campussafedb_activity6.dump`
- **File Size:** 47,160 bytes
- **Storage:** Local protected backup folder
- **Status:** Successfully created

## 4. SHA-256 Checksum

```text
E6D5515FC5734BC9BEBDBF66EDAC103DA770004C1994B9E97F71D05E83B3EC65
```

## 5. Backup Archive Inspection

Command used:

```powershell
pg_restore --list "C:\xampp\htdocs\jquery-fileupload-sessions\activity6_backups\grp07_campussafedb_activity6.dump"
```

Results:

- Archive format: CUSTOM
- PostgreSQL version: 14.24
- TOC Entries: 118
- Nine tables and their data entries were listed.
- Sequences, indexes, constraints, and foreign keys were present.

## 6. Result

The backup file was successfully created, its SHA-256 checksum was generated, and its archive contents were successfully inspected using `pg_restore --list`.

A separate restoration test is still required to confirm that the database can be recovered successfully.