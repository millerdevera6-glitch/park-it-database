# CampusSafe – Database Access Control Plan

## 1. Project Information

| Item | Description |
|---|---|
| Project Name | CampusSafe – Campus Hazard & Safety Reporting System |
| Group | Group 7 |
| Database | `grp07_campussafedb` |
| DBMS | PostgreSQL |
| Schema | `public` |
| Database Owner | `postgres` |
| Access Control Approach | Role-Based Access Control (RBAC) |

## 2. Access Control Objectives

The purpose of this access-control plan is to protect the CampusSafe database by assigning appropriate permissions to each database account.

The plan follows the principle of least privilege, which means that each account receives only the permissions needed to perform its assigned responsibilities.

The objectives are to:

- Separate application, reporting, and backup responsibilities.
- Prevent unauthorized database modifications.
- Protect sensitive user information, particularly password hashes.
- Restrict administrative privileges to authorized database administrators.
- Verify both permitted and denied database operations.

## 3. Database Structure

The CampusSafe database contains nine tables:

1. `app_user`
2. `role`
3. `hazard_report`
4. `hazard_category`
5. `campus_location`
6. `assignment`
7. `attachment`
8. `maintenance_action`
9. `report_status_history`

The database also contains nine sequences used by auto-incrementing identifiers.

All nine tables and sequences, as well as the database itself, are owned by `postgres`.

## 4. Role Design

The access-control implementation uses three group roles and three login roles.

### 4.1 Group Roles

| Group Role | Login Allowed | Responsibility |
|---|---|---|
| `app_runtime_grp` | No | Provides permissions required by the application. |
| `app_readonly_grp` | No | Provides read-only access for reporting and auditing. |
| `app_backup_grp` | No | Provides read access for database backup operations. |

### 4.2 Login Roles

| Login Role | Assigned Group Role | Responsibility |
|---|---|---|
| `campussafe_app` | `app_runtime_grp` | Application database operations. |
| `campussafe_report` | `app_readonly_grp` | Reporting and auditing queries. |
| `campussafe_backup` | `app_backup_grp` | Database backup and data retrieval. |

Group roles use `NOLOGIN`, while individual database accounts use `LOGIN`.

All three login accounts are non-superuser roles and do not have database creation, role creation, replication, or row-level security bypass privileges.

## 5. Permission Assignment

### 5.1 Application Runtime Account

Account: `campussafe_app`

Required permissions:

- SELECT, INSERT, and UPDATE on all existing tables.
- DELETE only on `attachment` and `assignment`.
- USAGE and SELECT on all existing sequences.
- CONNECT to `grp07_campussafedb`.
- USAGE on the `public` schema.

The account cannot directly delete hazard reports, user accounts, or other protected records.

### 5.2 Reporting and Auditor Account

Account: `campussafe_report`

Required permissions:

- SELECT on `hazard_report`.
- SELECT on `hazard_category`.
- SELECT on `campus_location`.
- SELECT on `report_status_history`.
- SELECT on `maintenance_action`.
- SELECT on `assignment`.
- SELECT on `attachment`.
- CONNECT to `grp07_campussafedb`.
- USAGE on the `public` schema.

The account cannot INSERT, UPDATE, or DELETE records.

Access to `app_user` and `role` is excluded to protect sensitive user information and restrict unnecessary access.

### 5.3 Backup Account

Account: `campussafe_backup`

Required permissions:

- SELECT on all existing tables.
- SELECT on all existing sequences.
- CONNECT to `grp07_campussafedb`.
- USAGE on the `public` schema.

The account cannot modify or delete database records.

The backup account is intended for read-only database backup operations.

## 6. Database and Schema Security

The following restrictions are implemented:

- PUBLIC privileges on `grp07_campussafedb` are revoked.
- CREATE permission on the `public` schema is revoked from PUBLIC.
- CONNECT permission is granted to the three designated group roles.
- USAGE permission on the `public` schema is granted to the three designated group roles.
- The application accounts do not receive superuser or database-administration privileges.

These restrictions help prevent unauthorized database connections and schema modifications.

## 7. Default Privileges

Default privileges are configured for future tables and sequences created by the role executing the default-privilege statements.

The runtime group receives:

- SELECT, INSERT, and UPDATE on future tables.
- USAGE and SELECT on future sequences.

The backup group receives:

- SELECT on future tables.
- SELECT on future sequences.

These default privileges do not automatically apply to objects created by other database owners. Additional default-privilege configuration may be needed if new objects are created under different owner roles.

## 8. Application-Level Access Control

CampusSafe also implements application-level role checks using PHP authentication and session management.

The application uses its `Auth::requireRole()` functionality to restrict features according to the authenticated user's role.

The database login accounts are shared by application users through the runtime connection. Therefore, PostgreSQL permissions control the application's database account, while PHP handles individual user access restrictions.

Both application-level and database-level controls are important for protecting the system.

## 9. Security Findings and Recommendations

During the access-control assessment, the following findings were identified:

### Finding 1: Connection to the PostgreSQL Administrative Database

The three application login accounts were able to connect to the separate `postgres` database.

This occurred because the access-control script revokes PUBLIC connection privileges only on `grp07_campussafedb`, not on the separate administrative database.

**Recommendation:** Review connection privileges on unrelated databases and restrict access according to administrative requirements.

### Finding 2: Difference Between Documentation and Database Permissions

The project documentation describes Admin as having full CRUD permissions on `app_user`, `hazard_category`, and `campus_location`.

However, the configured runtime group does not receive DELETE permission on these tables, and the inspected PHP model files did not show DELETE operations for these records.

**Recommendation:** Clarify the intended administrative operations and update either the documentation or the access-control design to keep them consistent.

### Finding 3: Shared Application Database Account

Application users share the `campussafe_app` database account.

This means PostgreSQL does not independently distinguish individual human users through their database login accounts.

**Recommendation:** Continue enforcing individual user permissions through PHP authentication and role checks. For stronger database-level accountability, consider a more advanced per-user database identity design if required.

## 10. Conclusion

The CampusSafe database access-control implementation separates application runtime, reporting, and backup responsibilities through PostgreSQL group roles and login roles.

The implementation follows the principle of least privilege by limiting modification and administrative permissions. Actual login tests and SQL permission checks were also conducted to verify the configured access restrictions.

The identified security findings provide recommendations for improving database isolation, documentation consistency, and accountability.