# COMP 018 — Activity 6: BrewPOS Database Backup, Restoration, and Recovery

This directory contains the complete Activity 6 engineering deliverables, automation scripts, SQL verification suites, and technical audit dossiers for the **BrewPOS — Café Point-of-Sale System**.

```
activity-6-brewpos/
├── README.md                           # Directory guide, roadmap, and quickstart commands
├── backup-plan.md                      # Comprehensive backup & disaster recovery architecture plan
├── backup.ps1                          # Automated PowerShell backup script (pg_dump -Fc + SHA-256)
├── restore.ps1                         # Automated PowerShell restoration script (safe createdb + pg_restore)
├── verification.sql                    # 12-point SQL post-restoration verification suite
├── recovery-simulation.sql             # SQL transcript for controlled data-loss recovery drill
├── roles-and-privileges.md             # RBAC mapping, table privileges matrix, and scope notes
└── documentation/
    ├── project-inspection.md           # Phase 1: Repository inspection & live schema audit
    ├── backup-report.md                # Phase 3: Backup creation evidence, SHA-256, and TOC inspection
    ├── restoration-report.md           # Phase 4: Isolated test restoration trace & object audit
    ├── verification-report.md          # Phase 5: 12-point verification scorecard & RBAC enforcement
    ├── recovery-report.md              # Phase 6: Controlled accidental-deletion recovery drill
    ├── final-report.md                 # Phase 7: Complete executive & technical final report
    └── final-report.pdf                # Generated publication-quality PDF report
```

---

## 1. Quickstart & Execution Guide (PowerShell on Windows)

### 1.1 Automated Backup Generation
Generates a custom compressed binary archive (`-Fc`), calculates its SHA-256 hash, and verifies the internal Table of Contents (TOC):
```powershell
.\activity-6-brewpos\backup.ps1 -Database "grp_brewposdb" -BackupDir "C:\Users\Matt\pg_backups\brewpos"
```

### 1.2 Isolated Test Database Restoration
Safely provisions an isolated database (checking for collisions) and restores the custom-format archive:
```powershell
.\activity-6-brewpos\restore.ps1 -TargetDatabase "grp_brewposdb_restore_test" -BackupFile "C:\Users\Matt\pg_backups\brewpos\grp_brewposdb_activity6.dump"
```

### 1.3 Post-Restoration SQL Verification Suite
Executes the comprehensive 12-point structural, data parity, and RBAC verification checks:
```bash
psql -U postgres -h localhost -p 5432 -d grp_brewposdb_restore_test -f activity-6-brewpos/verification.sql
```

### 1.4 Controlled Disaster Recovery Simulation
Executes the simulated accidental deletion, out-of-place staging restoration, and surgical data recovery:
```bash
psql -U postgres -h localhost -p 5432 -f activity-6-brewpos/recovery-simulation.sql
```

---

## 2. Activity 6 Key Findings & Technical Evidence

| Metric / Checkpoint | Technical Finding | Status |
|---|---|:---:|
| **Primary Database** | `grp_brewposdb` (Schema: `public`, 5 tables, 4 sequences) | **PRESERVED** |
| **Backup File** | `grp_brewposdb_activity6.dump` (Custom format `-Fc`, gzip compressed) | **CREATED** |
| **Backup File Size** | **17,897 bytes** (17.47 KB) | **VERIFIED** |
| **SHA-256 Hash** | `E721EFE29FE9D378617BD065E671B6D7DF4BCCFC049E66065E1B3DF05B563C9F` | **VERIFIED** |
| **Archive TOC Entries** | **52 entries** (Tables, Sequences, Constraints, COPY Data, ACLs) | **VERIFIED** |
| **Restored Test DB** | `grp_brewposdb_restore_test` | **RESTORED** |
| **Row Count Parity** | 100% Match across all 5 tables (30/30 total rows) | **PASS** |
| **RBAC Security** | Runtime `SELECT` permitted; unprivileged `DELETE` blocked (Error 42501) | **PASS** |
| **Recovery Staging DB** | `grp_brewposdb_recovery_test` | **RESTORED** |
| **Disaster Recovery Drill** | Accidental deletion surgically recovered with **0% permanent loss** | **PASS** |
| **Overall Certification** | All 8 Phases executed with zero warnings/errors | **CERTIFIED** |

