# BoardTrack – Database Administration Activity 6 Deliverables
## Database Backup, Restoration, and Recovery Suite

**Course:** COMP 018 – Database Administration  
**Project:** BoardTrack – Property and Rental Management System  
**Repository Source:** `https://github.com/karlrobertc-art/BoardTrack.git`  
**Target Database:** `boardtrack_db`  
**Restoration Staging Database:** `boardtrack_db_activity6_restore_test`  
**Disaster Recovery Database:** `boardtrack_db_activity6_recovery_test`  
**Date:** 2026-11-06  

---

### Deliverables Directory Structure

```text
activity-6-boardtrack/
│
├── README.md                   # This directory guide & execution index
├── backup-plan.md              # Disaster recovery & backup architecture plan
├── backup.ps1                  # Automated PowerShell logical backup utility (pg_dump -Fc)
├── restore.ps1                 # Automated PowerShell restoration utility (pg_restore)
├── verification.sql            # Comprehensive SQL verification suite (13 inspection categories)
├── recovery-simulation.sql     # Controlled data loss & point-in-time recovery SQL drill
├── roles-and-privileges.md     # Cluster-wide roles architecture & production setup DDL
│
└── documentation/              # Technical reports & evidence
    ├── project-inspection.md   # Phase 1: Repository inspection & schema inventory
    ├── backup-report.md        # Phase 3: Backup creation, checksum, and TOC audit
    ├── restoration-report.md   # Phase 4: Isolated staging restoration report
    ├── verification-report.md  # Phase 5: Quantitative & access control verification report
    ├── recovery-report.md      # Phase 6: Controlled recovery simulation & RPO gap report
    ├── final-report.md         # Phase 7: Complete technical audit report (Markdown)
    ├── final-report.html       # Print-ready styled HTML report
    └── final-report.pdf        # Formal PDF submission report (compiled via Edge headless)
```

---

### Quick Execution Guide

#### 1. Perform Automated Logical Backup
```powershell
.\backup.ps1 -DatabaseName "boardtrack_db" -Username "postgres" -HostName "localhost" -Port 5432
```
*Creates custom-format compressed archive (`-Fc`) at `$env:LOCALAPPDATA\PostgreSQL\Backups\boardtrack_activity6.dump`, verifies file existence, computes SHA-256 hash, and runs `pg_restore --list`.*

#### 2. Restore into Isolated Test Database
```powershell
.\restore.ps1 -TargetDatabase "boardtrack_db_activity6_restore_test" -Username "postgres"
```
*Provisions isolated target database via `createdb` and executes `pg_restore` safely without overwriting live databases.*

#### 3. Run Automated Verification Suite
```powershell
psql -U postgres -h localhost -p 5432 -d boardtrack_db_activity6_restore_test -f verification.sql
```
*Audits all 8 base tables, columns, constraints, exclusion rules, sequences, computed view `v_lease_summary`, row counts, and access controls.*

#### 4. Execute Disaster Recovery Simulation Drill
```powershell
psql -U postgres -h localhost -p 5432 -d boardtrack_db_activity6_restore_test -f recovery-simulation.sql
```
*Inserts dedicated disposable test record, simulates accidental deletion, provisions `boardtrack_db_activity6_recovery_test`, and verifies recovered state.*

---

### Security and Safety Compliance
1. **Original Database Preservation:** The active database state is never dropped, modified, or overwritten.
2. **Dedicated Disposable Targets:** All operations occur within isolated databases (`_restore_test` and `_recovery_test`).
3. **Zero Plaintext Secrets:** Authentication uses local `pgpass.conf` or environment mechanisms; zero credentials are stored in scripts or logs.
4. **Git Protection:** Backup binary dumps (`*.dump`, `*.tar`, `*.sql.gz`) and environment files (`.env`) are excluded from version control.

