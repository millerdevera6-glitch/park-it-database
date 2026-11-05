# CampusSafe – Database Access Control Verification Results

## 1. Verification Overview

The database access-control configuration was tested using PostgreSQL to determine whether each login role could perform only its permitted operations.

The tests covered:

- Database login authentication.
- Role memberships.
- Login-role security attributes.
- Database and schema permissions.
- Table privileges.
- Sequence privileges.
- Allowed and denied SQL operations.
- Database object ownership.

Database: `grp07_campussafedb`

DBMS: PostgreSQL

Schema: `public`

## 2. Login Authentication Tests

The three database accounts were tested using SQL Shell (psql).

| Login Account | Expected Result | Actual Result | Status |
|---|---|---|---|
| `campussafe_app` | Successful connection | Successful connection | PASS |
| `campussafe_report` | Successful connection | Successful connection | PASS |
| `campussafe_backup` | Successful connection | Successful connection | PASS |

All three accounts successfully authenticated using their updated passwords.

## 3. Role Membership Verification

The PostgreSQL role membership query confirmed the following assignments:

| Login Role | Group Role | Status |
|---|---|---|
| `campussafe_app` | `app_runtime_grp` | PASS |
| `campussafe_report` | `app_readonly_grp` | PASS |
| `campussafe_backup` | `app_backup_grp` | PASS |

Each login role belongs to its intended group role.

## 4. Login-Role Security Attributes

The `pg_roles` catalog was queried to verify the administrative attributes of the three login roles.

| Attribute | campussafe_app | campussafe_report | campussafe_backup |
|---|---|---|---|
| LOGIN | TRUE | TRUE | TRUE |
| SUPERUSER | FALSE | FALSE | FALSE |
| CREATEDB | FALSE | FALSE | FALSE |
| CREATEROLE | FALSE | FALSE | FALSE |
| REPLICATION | FALSE | FALSE | FALSE |
| BYPASSRLS | FALSE | FALSE | FALSE |

**Result:** PASS

All three accounts can authenticate but do not have unnecessary administrative privileges.

## 5. Database and Schema Permission Verification

The database and schema permissions were checked using PostgreSQL privilege functions.

| Permission | campussafe_app |
|---|---|
| CONNECT to CampusSafe database | TRUE |
| USAGE on public schema | TRUE |
| CREATE on public schema | FALSE |

The three designated group roles were also granted CONNECT to the CampusSafe database and USAGE on the public schema.

**Result:** PASS

## 6. Table Permission Verification

### 6.1 Application Runtime Account

The `campussafe_app` account was granted SELECT, INSERT, and UPDATE on all nine existing tables.

DELETE is restricted to:

- `attachment`
- `assignment`

It cannot directly delete records from protected tables such as `app_user` and `hazard_report`.

### 6.2 Reporting Account

The `campussafe_report` account has SELECT access to seven operational tables:

- `hazard_report`
- `hazard_category`
- `campus_location`
- `report_status_history`
- `maintenance_action`
- `assignment`
- `attachment`

It does not have access to `app_user` or `role`, and cannot modify records.

### 6.3 Backup Account

The `campussafe_backup` account has SELECT access to all nine existing tables but cannot modify or delete records.

**Result:** PASS

The table privilege checks matched the configured role permissions.

## 7. Sequence Permission Verification

The nine database sequences were checked.

| Account | SELECT | USAGE | UPDATE |
|---|---|---|---|
| `campussafe_app` | TRUE | TRUE | FALSE |
| `campussafe_report` | FALSE | FALSE | FALSE |
| `campussafe_backup` | TRUE | FALSE | FALSE |

**Result:** PASS

The runtime account has the sequence permissions needed for its application operations. The reporting account has no sequence privileges, while the backup account has read-only sequence access.

## 8. SQL Operation Tests

The following SQL operations were executed using the respective login accounts.

### Test 1: Application INSERT Permission

Account: `campussafe_app`

```sql
INSERT INTO public.report_status_history
(report_id, changed_by_user_id, status, notes)
VALUES (1, 1, 'Submitted', 'Activity 4 permission test');
```

Expected result: INSERT allowed.

Actual result: `INSERT 0 1`

Status: PASS

The test record was subsequently removed by the PostgreSQL administrator account.

### Test 2: Application DELETE Restriction

Account: `campussafe_app`

```sql
DELETE FROM public.report_status_history
WHERE report_id = 1
  AND changed_by_user_id = 1
  AND notes = 'Activity 4 permission test';
```

Expected result: DELETE denied.

Actual result: Permission denied for table `report_status_history`.

Status: PASS

The application account does not have DELETE permission on this table, as intended.

### Test 3: Reporting Account UPDATE Restriction

Account: `campussafe_report`

```sql
UPDATE public.hazard_report
SET status = status
WHERE report_id = 1;
```

Expected result: UPDATE denied.

Actual result: Permission denied for table `hazard_report`.

Status: PASS

### Test 4: Reporting Account Sensitive Table Restriction

Account: `campussafe_report`

```sql
SELECT * FROM public.app_user;
```

Expected result: SELECT denied.

Actual result: Permission denied for table `app_user`.

Status: PASS

This confirms that the reporting account cannot directly access the user table containing sensitive account information.

### Test 5: Backup Account SELECT Permission

Account: `campussafe_backup`

```sql
SELECT * FROM public.hazard_report
LIMIT 5;
```

Expected result: SELECT allowed.

Actual result: Five records were successfully retrieved.

Status: PASS

### Test 6: Backup Account UPDATE Restriction

Account: `campussafe_backup`

```sql
UPDATE public.hazard_report
SET status = status
WHERE report_id = 1;
```

Expected result: UPDATE denied.

Actual result: Permission denied for table `hazard_report`.

Status: PASS

## 9. Database Ownership Verification

The database ownership query confirmed:

| Database Object | Owner |
|---|---|
| `grp07_campussafedb` | `postgres` |
| All nine tables | `postgres` |
| All nine sequences | `postgres` |

**Result:** PASS

The application login accounts do not own the database objects.

## 10. Additional Security Finding

The three application login accounts were able to connect to the separate PostgreSQL `postgres` database.

This indicates that the connection restriction configured for `grp07_campussafedb` does not automatically restrict connections to other databases.

Recommendation: Review and restrict CONNECT privileges on unrelated databases according to administrative requirements.

## 11. Overall Verification Summary

| Verification Area | Result |
|---|---|
| Database setup | PASS |
| Login authentication | PASS |
| Role memberships | PASS |
| Login-role attributes | PASS |
| Database and schema permissions | PASS |
| Table permissions | PASS |
| Sequence permissions | PASS |
| Allowed INSERT operation | PASS |
| Restricted DELETE operation | PASS |
| Restricted UPDATE operation | PASS |
| Restricted sensitive-table access | PASS |
| Database ownership | PASS |

## 12. Conclusion

The CampusSafe database access-control configuration was successfully verified through actual PostgreSQL login tests, privilege checks, and SQL operations.

The results demonstrate that the runtime, reporting, and backup accounts have different levels of access based on their responsibilities.

Unauthorized operations were rejected by PostgreSQL, while permitted operations were completed successfully. Additional security findings were documented for future improvement.