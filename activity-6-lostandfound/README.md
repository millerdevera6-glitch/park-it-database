# COMP 018 — Database Administration
## Activity 6: Database Backup, Restoration, and Recovery
### Project: PUP-SPOT — Campus Lost and Found System

---

## 📌 Project & Environment Overview

- **Project Name:** PUP-SPOT – Campus Lost and Found
- **Repository:** `https://github.com/grp05-dba/grp05_lostandfound.git`
- **Database Engine:** PostgreSQL 18.6 (x64 Windows)
- **Primary Database:** `grp05_lostandfounddb`
- **Restoration Test Database:** `grp05_lostandfounddb_restore_test`
- **Recovery Simulation Database:** `grp05_lostandfounddb_recovery_test`
- **Application Backend:** PHP 8.0+ (PDO PostgreSQL)
- **Host / Port:** `localhost:5432`

---

## 📁 Activity 6 Directory Structure

```text
activity-6-lostandfound/
├── README.md                      # Navigation guide and execution overview
├── backup-plan.md                 # Phase 2: Enterprise backup policy & architecture
├── backup.ps1                     # Phase 3: Automated PowerShell logical backup script
├── restore.ps1                    # Phase 4: Automated PowerShell restore script
├── verification.sql               # Phase 5: Comprehensive SQL schema and data validation suite
├── recovery-simulation.sql        # Phase 6: Controlled deletion and recovery simulation script
├── roles-and-privileges.md        # Comprehensive PostgreSQL RBAC documentation & reproduction guide
├── backup/                        # Dedicated directory for binary dumps (ignored by Git)
│   └── grp05_lostandfounddb_activity6.dump
└── documentation/
    ├── project-inspection.md      # Phase 1: Thorough repository & live schema audit
    ├── backup-report.md           # Phase 3: Backup execution, verification, hash, and TOC evidence
    ├── restoration-report.md      # Phase 4: Full restoration evidence and analysis
    ├── verification-report.md     # Phase 5: Verification matrix (PASS/FAIL/NEEDS REVIEW)
    ├── recovery-report.md         # Phase 6: Simulated incident and point-in-time recovery audit
    └── final-report.md            # Comprehensive consolidated report (PDF-ready)
```

---

## 🛡️ Critical Safety Guidelines Followed

1. **Zero Impact on Production Database:** The original database (`grp05_lostandfounddb`) was verified beforehand and kept untouched during all restoration, testing, and simulation phases.
2. **Dedicated Test Environments:** All restores and recovery experiments were executed in isolated databases (`grp05_lostandfounddb_restore_test` and `grp05_lostandfounddb_recovery_test`).
3. **No Secrets in Source Control:** No database passwords or sensitive environment keys are stored in scripts or markdown files.
4. **Binary Dump Isolation:** Dump files (`*.dump`) and the `backup/` folder are excluded via `.gitignore` to prevent repository bloat and credential exposure.
5. **Least-Privilege Role Auditing:** Access control checks verified permissions using dedicated application roles (`lostandfound_app` and `lostandfound_public`).

---

## 🚀 Quick Execution Guide

### 1. Perform Backup
```powershell
.\backup.ps1
```
Creates `grp05_lostandfounddb_activity6_<timestamp>.dump` in the `backup/` folder using `pg_dump -Fc` and computes its SHA-256 hash.

### 2. Restore Backup to Test Database
```powershell
.\restore.ps1 -TargetDatabase "grp05_lostandfounddb_restore_test"
```
Creates the target test database (if not existing) and runs `pg_restore -v` safely without impacting the production database.

### 3. Run Verification Suite
```powershell
psql -U postgres -h localhost -p 5432 -d grp05_lostandfounddb_restore_test -f verification.sql
```

### 4. Run Recovery Simulation
```powershell
psql -U postgres -h localhost -p 5432 -d grp05_lostandfounddb_restore_test -f recovery-simulation.sql
```

