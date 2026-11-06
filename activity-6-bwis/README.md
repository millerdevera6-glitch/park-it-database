# COMP 018 Activity 6 Deliverables: Database Backup, Restoration, and Recovery
## BWIS IT Solutions – Campus Canteen Pre-Order & Queue Management System

This directory (`activity-6-bwis/`) contains the complete implementation, automation scripts, verification suites, and technical documentation for **COMP 018 (Database Administration) – Activity 6**.

---

## 1. Directory Structure

```text
activity-6-bwis/
│
├── README.md                     # Overview, file manifest, and quickstart execution guide
├── backup-plan.md                # Formal 12-point backup, RPO/RTO, retention, and DR plan
├── backup.ps1                    # Production-grade PowerShell script for pg_dump -Fc backups
├── restore.ps1                   # Safe PowerShell restoration script into isolated test databases
├── verification.sql              # 12-check SQL suite verifying tables, constraints, data, and ACLs
├── recovery-simulation.sql       # Controlled disaster simulation SQL script (accidental deletion)
├── roles-and-privileges.md       # Analysis of application vs. PostgreSQL roles and ACL behavior
│
└── documentation/                # In-depth technical activity reports
    ├── project-inspection.md     # Phase 1: Deep repository, stack, and database schema audit
    ├── backup-report.md          # Phase 3: Backup metadata, size, SHA-256, and TOC analysis
    ├── restoration-report.md     # Phase 4: Restoration execution, exit codes, and ACL analysis
    ├── verification-report.md    # Phase 5: 15-point verification matrix (100% Passed)
    ├── recovery-report.md        # Phase 6: Controlled recovery simulation and RPO evaluation
    ├── final-report.md           # Phase 7: Comprehensive final progress report
    └── COMP018_Activity6_Final_Report.pdf # PDF-ready printable report
```

---

## 2. Key Findings & Execution Summary

- **Database Engine:** PostgreSQL 18.6 on x86_64-windows (Port 5432).
- **Target Database:** `canteendb` (7 application tables, 7 serial sequences).
- **Backup File:** `bwis_activity6.dump` (Custom Archive Format `-Fc`).
- **Backup Size:** **25,798 bytes** (25.19 KB).
- **SHA-256 Checksum:** `8C89EE1569E27279855B68EF08325F44E60E9796D9211EF89A91B3F433118EAD`.
- **Restoration Target:** `canteendb_activity6_restore_test` (Exit Code: 0, 100% Passed).
- **Recovery Simulation Target:** `canteendb_activity6_recovery_test` (Exit Code: 0, 100% Bit-for-bit exact match: SHA-256 `af2e58b68913...`).
- **Original Database State:** `canteendb` preserved 100% untouched throughout all phases.

---

## 3. How to Run the Scripts

### Prerequisites
- Windows PowerShell 5.1 or PowerShell 7+.
- PostgreSQL 18 client tools (`pg_dump`, `pg_restore`, `createdb`, `psql`) installed in `C:\Program Files\PostgreSQL\18\bin` or on system PATH.
- Local PostgreSQL authentication configured via `%APPDATA%\postgresql\pgpass.conf` or `$env:PGPASSWORD`.

### Step 1: Perform Automated Backup
```powershell
powershell -ExecutionPolicy Bypass -File .\activity-6-bwis\backup.ps1 -DbName "canteendb" -BackupDir "C:\secure_backups"
```

### Step 2: Restore into Separate Test Database
```powershell
powershell -ExecutionPolicy Bypass -File .\activity-6-bwis\restore.ps1 -BackupFile "C:\secure_backups\canteendb_YYYYMMDD_HHMMSS.dump" -TargetDbName "canteendb_activity6_restore_test"
```

### Step 3: Run Post-Restoration Verification Suite
```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h 127.0.0.1 -p 5432 -d canteendb_activity6_restore_test -f .\activity-6-bwis\verification.sql
```

### Step 4: Run Controlled Recovery Simulation
```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h 127.0.0.1 -p 5432 -d canteendb_activity6_restore_test -f .\activity-6-bwis\recovery-simulation.sql
```

