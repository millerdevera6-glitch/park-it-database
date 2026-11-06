# Database Backup, Restoration, and Recovery Plan
**Course:** COMP 018 – Database Administration  
**Project:** OJT Management System  
**Database System:** PostgreSQL (Version 18.x)  
**Database Name:** `ojt_managementdb`  
**Author:** Student DBA Team  
**Date:** 2026-11-06  

---

## 1. Scope and Database Objects to Be Backed Up

This backup plan applies to the production database of the OJT Management System: **`ojt_managementdb`**.

### Objects Covered in Backup
1. **Schemas:** `public` and all associated metadata.
2. **Tables (12 core entities):**
   - `users` (Authentication & identity records)
   - `audit_log` (System operational audit trail)
   - `students` (Student profile and academic standing)
   - `companies` (Host Training Establishments / Partner companies)
   - `academic_supervisors` (Faculty supervisor profiles)
   - `company_supervisors` (Industry mentor profiles)
   - `requirements` (Internship document requirements catalog)
   - `ojt_applications` (Student placement applications)
   - `student_requirements` (Requirement submissions and verification status)
   - `ojt_placements` (Active and completed internship contracts)
   - `attendance` (Daily time logs and supervisor verifications)
   - `evaluations` (Company supervisor performance evaluations)
3. **Relational Constraints & Integrity:**
   - Primary Keys (`*_pkey`)
   - Foreign Keys (`*_fkey`, composite consistency keys)
   - Unique constraints (`users_username_key`, `users_email_key`, composite pairs)
   - Domain Check constraints (`role`, `status`, `year_level`, `score`, `dates`)
4. **Sequences:**
   - All `SERIAL` sequences associated with table primary keys.
5. **Roles and Permissions:**
   - Standalone export of database login roles (`ojt_admin`, `ojt_student`, `ojt_academic_supervisor`, `ojt_company_supervisor`, `ojt_coordinator`) and their least-privilege grants via `roles-and-privileges.sql`.

---

## 2. Backup Method and Technical Justification

### Selected Format: PostgreSQL Custom Archive Format (`pg_dump -Fc`)
The primary backup mechanism will utilize PostgreSQL's native `pg_dump` utility with the **Custom Archive format (`-Fc`)**.

```bash
pg_dump -U postgres -h localhost -p 5432 -Fc -d ojt_managementdb -f ojt_managementdb_activity6.dump
```

### Technical Justification
| Feature | Custom Archive (`-Fc`) | Plain Text SQL (`-Fp`) | Directory / Tar (`-Fd` / `-Ft`) |
| :--- | :--- | :--- | :--- |
| **Compression** | Built-in zlib/gzip compression, minimizing storage footprint | No compression by default (large file sizes) | Directory compresses per table; Tar does not compress |
| **Flexibility** | Supports selective table/schema restore and reordering via `pg_restore` | All-or-nothing sequential execution | Flexible, but multi-file or tar overhead |
| **Archive Inspection** | Allows inspecting archive contents (`pg_restore --list`) without restoring | Requires manual text parsing | Complex inspection |
| **Error Handling** | Atomic table restores and detailed error tracking | Fails or cascades errors mid-script | Varies |
| **Cross-Platform** | Completely platform-independent binary format | Vulnerable to newline / charset encoding bugs | Complex directory copying |

---

## 3. Backup Storage Location and Security

### Storage Directory Structure
All backups will be stored locally in a dedicated, isolated directory excluded from version control:
```text
c:\Users\Matt\Downloads\ACTIVITY 6 G3\
└── db-backup-recovery\
    └── backups\                          # Excluded via .gitignore
        ├── ojt_managementdb_activity6.dump
        └── ojt_managementdb_activity6.dump.sha256
```

### Access Restrictions & Protection
1. **Operating System Level:** Directory access restricted to the Database Administrator account and the designated OS backup service account.
2. **Version Control Exclusion:** `.gitignore` strictly rules out `*.dump`, `*.tar`, `*.bak`, `*.sql.gz`, and all files in `backups/` to avoid data leakage or credential exposure to GitHub.
3. **Immutability:** Once written and verified, backup archives are marked read-only.

---

## 4. Authorized Accounts and Least Privilege

Only authorized administrative accounts are permitted to perform backup and restoration tasks:

| Role / Account | Privilege Level | Permitted Operations |
| :--- | :--- | :--- |
| `postgres` (Superuser) | System Administrator | Full cluster backup, database creation, role creation, recovery execution. |
| `ojt_backup_operator` | Dedicated Maintenance Role | Read-only access to all schemas and sequences for scheduled unattended dumps. |
| Application Roles (`ojt_admin`, `ojt_student`, etc.) | End-User Application | **Denied** from executing `pg_dump`, `createdb`, or `dropdb`. |

---

## 5. Backup Verification Procedures

A backup is not considered complete until it passes the **Three-Stage Verification Protocol**:

1. **Archive Integrity Verification:**
   - Execute `pg_restore --list <dumpfile>` to confirm TOC (Table of Contents) headers, table data entries, and compression blocks are non-corrupted.
2. **Cryptographic Checksum Verification:**
   - Compute the SHA-256 hash immediately upon dump completion and write to `.sha256` file:
     ```powershell
     Get-FileHash -Algorithm SHA256 ojt_managementdb_activity6.dump
     ```
3. **Restoration & Automated SQL Testing:**
   - Restore the dump into an isolated staging database (`ojt_managementdb_restore_test`).
   - Execute `verification.sql` to ensure all 12 tables, relationships, constraints, and record counts match the baseline production database exactly.

---

## 6. Proposed Backup Schedule

| Frequency | Backup Type | Execution Time | Retention |
| :--- | :--- | :--- | :--- |
| **Daily** | Full Custom Dump (`-Fc`) | 02:00 AM (Low operational traffic) | 14 Days |
| **Weekly** | Full Custom Dump + Globals | Every Sunday at 01:00 AM | 5 Weeks |
| **Monthly** | Cold Archive Dump | 1st of each month | 12 Months |
| **Continuous** | Write-Ahead Log (WAL) Archiving | Real-time / 15-minute segments | 7 Days |

---

## 7. Backup Retention Policy (Grandfather-Father-Son)

To balance storage economy with recovery readiness, a **Grandfather-Father-Son (GFS)** policy is established:
- **Son (Daily):** Retain daily backups for **14 days**.
- **Father (Weekly):** Retain weekly full backups for **5 weeks**.
- **Grandfather (Monthly):** Retain monthly milestone backups for **12 months**.
- **Annual Archive:** Permanent cold storage for annual fiscal audit records.
- Automated purge scripts safely delete expired dumps exceeding the retention threshold after verifying younger backups exist.

---

## 8. Recovery Point Objective (RPO)

- **Target RPO:** **&le; 1 hour** (during regular university working hours).
- **Baseline RPO (without continuous WAL archiving):** **24 hours** (maximum potential data loss equals the data generated since the 02:00 AM daily dump).
- **Critical Data Protection:** Key internship contracts, company evaluations, and final grades are protected by real-time audit logging in `audit_log`.

---

## 9. Recovery Time Objective (RTO)

- **Target RTO:** **&le; 15 minutes**.
- **Recovery Breakdown:**
  1. Incident Detection & Decision to Recover: 3 minutes.
  2. Target Database Provisioning (`createdb`): 1 minute.
  3. Archive Extraction & Restoration (`pg_restore`): 4 minutes.
  4. Automated Data & Constraint Verification (`verification.sql`): 2 minutes.
  5. Application Redirect & Smoke Testing: 5 minutes.

---

## 10. Role and Privilege Re-creation Procedure

Because database-level backups (`pg_dump`) do not contain cluster-level global objects (such as roles, users, and passwords), roles must be restored independently:

1. **Global Roles Export:**
   ```bash
   pg_dumpall -U postgres -h localhost -p 5432 --globals-only -f cluster-globals.sql
   ```
2. **Application Role Script:**
   - Execute `roles-and-privileges.sql` which defines idempotent role creation:
     ```sql
     DO $$
     BEGIN
       IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'ojt_admin') THEN
         CREATE ROLE ojt_admin LOGIN;
       END IF;
       -- (repeated for student, supervisors, coordinator)
     END
     $$;
     ```
3. **Privilege Re-application:**
   - Grants `CONNECT` on the restored database, `USAGE` on schema `public`, and specific DML/Sequence privileges.

