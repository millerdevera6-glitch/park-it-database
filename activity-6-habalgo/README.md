# HabalGo – COMP 018 Activity 6: Database Backup, Restoration, and Recovery

This directory contains the complete deliverables, operational scripts, execution logs, and technical reports for **COMP 018 – Database Administration, Activity 6** for the **HabalGo** project.

---

## Deliverables Index

```
activity-6-habalgo/
├── README.md                      # Operational guide and directory overview
├── backup-plan.md                 # Complete disaster recovery & backup specification
├── backup.ps1                     # PowerShell automated backup script (pg_dump -Fc)
├── restore.ps1                    # PowerShell automated restoration script (pg_restore)
├── verification.sql               # Complete SQL verification script for restored databases
├── recovery-simulation.sql        # Controlled disaster recovery simulation SQL script
├── roles-and-privileges.md        # Comprehensive access control & RBAC documentation
└── documentation/
    ├── project-inspection.md      # Phase 1: Comprehensive Project & DB Inspection Report
    ├── backup-report.md           # Phase 3: Backup Creation & Archive Inspection Report
    ├── restoration-report.md      # Phase 4: Restored Test Database Report
    ├── verification-report.md     # Phase 5: Database Verification & Access Control Audit
    ├── recovery-report.md         # Phase 6: Controlled Disaster Recovery Simulation Report
    ├── final-report.md            # Phase 7: Consolidated Final Report (PDF Ready)
    └── final-report.pdf           # Phase 7: Compiled Official PDF Submission
```

---

## Key System Parameters

- **Database Engine:** PostgreSQL 18.6 (x86_64-windows)
- **Active Operational Database:** `grp00_habalgodb`
- **Application Schema:** `habalgo`
- **Tables (8):** `booking`, `customer`, `driver`, `driver_vehicle`, `location`, `payment`, `rating_feedback`, `vehicle`
- **Restoration Test Database:** `grp00_habalgodb_activity6_restore_test`
- **Recovery Test Database:** `grp00_habalgodb_recovery_test`
- **Backup File:** `habalgo_activity6.dump` (PostgreSQL Custom Format `-Fc`, gzip compressed)
- **SHA-256 Checksum:** `3CF5A86D91B9854F5D133737BB3ABD8459B99EE1A483C979840C3825518CA2E0`
- **Backup Location:** Stored securely outside the Git repository in compliance with database safety rules.

---

## How to Execute the Scripts

### 1. Run Automated Backup
```powershell
# Executes pg_dump -Fc, verifies SHA-256 checksum, and inspects archive TOC
.\activity-6-habalgo\backup.ps1 -DatabaseName "grp00_habalgodb"
```

### 2. Run Automated Restoration to Test Database
```powershell
# Safely restores into an isolated test environment without touching production
.\activity-6-habalgo\restore.ps1 -TargetDatabase "grp00_habalgodb_activity6_restore_test"
```

### 3. Run Post-Restoration SQL Verification
```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -p 5432 -d grp00_habalgodb_activity6_restore_test -f .\activity-6-habalgo\verification.sql
```

### 4. Run Controlled Recovery Simulation
```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -p 5432 -f .\activity-6-habalgo\recovery-simulation.sql
```

---

## Safety Guarantees Upheld
1. The original production database `grp00_habalgodb` was never dropped, overwritten, or modified.
2. No genuine application records were deleted.
3. No database passwords or secrets are committed.
4. Database dumps are stored outside the Git repository and protected via `.gitignore`.
5. Least privilege access controls were empirically verified and documented.

