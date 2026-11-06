# CampusSafe – Activity 4 Database Access Control Assessment

## Project Information

| Item | Details |
|---|---|
| Project | CampusSafe – Campus Hazard & Safety Reporting System |
| Group | Group 7 |
| Repository | [CampusSafe GitHub Repository](https://github.com/jeffersonorpesa2-ops/grp07-campussafe) |
| Database | `grp07_campussafedb` |
| DBMS | PostgreSQL |
| Schema | `public` |

## Overview

This folder contains the database access-control assessment for the CampusSafe project as part of COMP 018 – Database Administration Activity 4.

The assessment focuses on PostgreSQL role creation, role memberships, privilege assignment, and verification of permitted and restricted database operations.

The implementation follows the principle of least privilege by separating application runtime, reporting, and backup responsibilities.

## Folder Contents

| File/Folder | Description |
|---|---|
| `access-control-plan.md` | Documents the access-control objectives, role design, permissions, and security recommendations. |
| `verification-results.md` | Records actual login tests, permission checks, SQL operations, and their results. |
| `evidence/` | Contains screenshots of database setup, role configuration, permissions, and verification tests. |
| `scripts/` | Contains the SQL scripts used for database setup and access-control configuration. |

## Configured Database Roles

| Login Role | Group Role | Purpose |
|---|---|---|
| `campussafe_app` | `app_runtime_grp` | Application database operations |
| `campussafe_report` | `app_readonly_grp` | Reporting and auditing |
| `campussafe_backup` | `app_backup_grp` | Read-only backup operations |

## Assessment Activities

The following activities were completed:

1. Created the CampusSafe PostgreSQL database.
2. Executed the schema and seed scripts.
3. Created group roles and login roles.
4. Assigned login roles to their corresponding group roles.
5. Configured database, schema, table, and sequence privileges.
6. Verified role attributes and memberships.
7. Tested allowed and denied SQL operations.
8. Reviewed database object ownership.
9. Documented security findings and recommendations.

## How to Review

Start with `access-control-plan.md` to understand the access-control design.

Next, review `verification-results.md` to see the actual test results.

The `evidence/` folder contains screenshots supporting the verification results.

## Security Notice

The SQL scripts use placeholder passwords. Replace these placeholders with unique local passwords before creating new login accounts.

Never commit actual database passwords or other credentials to the repository.

## Conclusion

The assessment demonstrates the use of PostgreSQL role-based access control and least-privilege permissions to protect the CampusSafe database.

The verification results show that permitted operations were successful and restricted operations were rejected by PostgreSQL.