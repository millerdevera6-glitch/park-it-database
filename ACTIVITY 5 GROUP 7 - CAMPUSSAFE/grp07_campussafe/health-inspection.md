# Database Health Inspection – Group 7 CampusSafe

## 1. Database Information

- Database Name: grp07_campussafedb
- PostgreSQL Version: 14.24
- Database Size: 9,491 kB
- Total Public Tables: 9
- Connected Account During Inspection: postgres

## 2. Database Tables

The database contains nine public tables:

1. app_user
2. assignment
3. attachment
4. campus_location
5. hazard_category
6. hazard_report
7. maintenance_action
8. report_status_history
9. role

## 3. Connection Monitoring

The database inspection showed one connected backend session. The session belonged to postgres through the psql application.

No long-running query was identified in the inspected activity snapshot. The monitoring query itself appeared as the active query.

## 4. Activity 4 Roles and Accounts

The following roles were found:

- app_runtime_grp
- app_readonly_grp
- app_backup_grp
- campussafe_app
- campussafe_report
- campussafe_backup

The three login accounts were configured with their corresponding group-role memberships. None of the three login accounts had superuser, CREATEDB, or CREATEROLE privileges.

## 5. Database Health Assessment

The database was available and accepted connections during inspection. Its size was 9,491 kB, with nine public tables.

Most tables had zero estimated dead rows. The report_status_history table had two estimated dead rows.

## 6. Overall Assessment

The database was operational during the inspection. Existing indexes were present on important report-related columns. PostgreSQL logs contained authentication failures, permission-denied events, and a statistics-file permission warning that should be reviewed.