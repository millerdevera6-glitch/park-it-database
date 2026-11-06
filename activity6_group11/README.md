# COMP 018 — Activity 6: Database Backup, Restoration, and Recovery
## Project: BoardTrack — Boarding House & Rental Management System

**Course:** COMP 018 — Database Administration  
**Semester / Term:** Academic Year 2026–2027  
**Student Specialization:** Information Technology  
**Role:** Senior PostgreSQL Database Administrator / Node.js Developer  
**Target Database:** `boardtrack_db`  
**Engine:** PostgreSQL 18.6 (x86_64-windows)  

---

## 1. Project Directory Structure

All Activity 6 artifacts, PowerShell automation scripts, SQL verification suites, and technical documentation are organized within this directory:

```
activity-6-boardtrack/
├── README.md                           # Master guide and execution overview
├── backup-plan.md                      # Comprehensive enterprise backup & disaster recovery plan
├── backup.ps1                          # Automated PowerShell backup utility (pg_dump -Fc + SHA-256)
├── restore.ps1                         # Automated PowerShell restoration utility (createdb + pg_restore)
├── verification.sql                    # 15-section SQL database and access control verification suite
├── recovery-simulation.sql             # Controlled non-destructive disaster recovery simulation script
├── roles-and-privileges.md             # Role hierarchy, object grants, and access control audit
└── documentation/
    ├── project-inspection.md           # Phase 1: Repository and live catalog baseline audit
    ├── backup-report.md                # Phase 3: Backup execution, verification, and audit findings
    ├── restoration-report.md           # Phase 4: Test database restoration and ownership analysis
    ├── verification-report.md          # Phase 5: Schema verification and access control test matrix
    ├── recovery-report.md              # Phase 6: Controlled incident recovery simulation report
    ├── final-report.md                 # Phase 7: Consolidated enterprise final report
    └── final-report.pdf                # Phase 7: PDF publication of the final report
```

---

## 2. Quick Execution Guide

All scripts are fully automated, parameterized, and Windows PowerShell compatible.

### 2.1 Running the Automated Backup
```powershell
powershell -ExecutionPolicy Bypass -File .\backup.ps1 `
    -Database boardtrack_db `
    -Username postgres `
    -HostName localhost `
    -Port 5432 `
    -BackupDir .\backups
```
* **Operations Performed:** Verifies PostgreSQL readiness, queries catalog for database existence, executes `pg_dump -Fc`, generates SHA-256 cryptographic hash, and validates archive integrity via `pg_restore --list`.

### 2.2 Restoring to an Isolated Test Database
```powershell
powershell -ExecutionPolicy Bypass -File .\restore.ps1 `
    -TargetDatabase boardtrack_db_activity6_restore_test `
    -DumpFile .\backups\boardtrack_activity6.dump `
    -Username postgres `
    -HostName localhost `
    -Port 5432
```
* **Operations Performed:** Validates that target test database does not collide with existing databases, checks dump existence, provisions isolated database via `createdb`, and restores custom archive via `pg_restore`.

### 2.3 Running the Verification Suite
```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -p 5432 -d boardtrack_db_activity6_restore_test -f .\verification.sql
```
* **Audited Objects:** Verifies 8 tables, column types, primary keys, foreign keys (`ON DELETE NO ACTION`), unique constraints, check constraints, exclusion constraint (`ex_lease_no_overlap`), indexes, sequences, view `v_lease_summary`, triggers, row counts, and role privileges.

### 2.4 Executing the Disaster Recovery Simulation
```powershell
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -h localhost -p 5432 -d boardtrack_db_activity6_restore_test -f .\recovery-simulation.sql
```
* **Simulated Workflow:** Documents baseline of dedicated disposable test tenant (`ID: 999`), simulates accidental deletion, confirms data loss (0 rows), restores baseline backup into secondary recovery database (`boardtrack_db_activity6_recovery_test`), and reinstates the lost entity with 100% field fidelity.

---

## 3. Strict Safety Compliance

This activity strictly complies with all COMP 018 database safety rules:
1. **Zero Production Mutation:** Original databases on the cluster were never dropped, modified, or overwritten.
2. **Dedicated Test Namespaces:** Restoration and recovery testing strictly utilize designated disposable databases (`boardtrack_db_activity6_restore_test` and `boardtrack_db_activity6_recovery_test`).
3. **No Unvetted Database Seeding:** In accordance with Safety Rule 3 (*"Never initialize or reseed the original database"*) and Phase 3 directives, live backup execution was safely halted when catalog inspection confirmed `boardtrack_db` was unprovisioned on the live cluster.
4. **Credential Security:** All authentication operates non-interactively via `%APPDATA%\postgresql\pgpass.conf`. Zero passwords or plaintext secrets are disclosed in scripts, terminal outputs, or documentation.
5. **Version Control Safety:** Git ignore rules in `.gitignore` strictly exclude dump files (`*.dump`, `*.backup`, `*.tar`, `*.sql`), `.env`, and credential artifacts.

