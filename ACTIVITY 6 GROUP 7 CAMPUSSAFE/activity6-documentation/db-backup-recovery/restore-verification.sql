-- COMP 018 - Activity 6
-- CampusSafe Database Restoration Verification
-- Test database: grp07_campussafedb_restore_test

-- 1. List restored tables
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- 2. Check important record counts
SELECT 'app_user' AS table_name, COUNT(*) AS records FROM app_user
UNION ALL
SELECT 'hazard_report', COUNT(*) FROM hazard_report
UNION ALL
SELECT 'report_status_history', COUNT(*) FROM report_status_history
UNION ALL
SELECT 'role', COUNT(*) FROM role
ORDER BY table_name;

-- 3. Verify database constraints
SELECT
    contype,
    COUNT(*) AS total
FROM pg_constraint
WHERE connamespace = 'public'::regnamespace
GROUP BY contype
ORDER BY contype;

-- 4. Verify table permissions
SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN (
    'app_runtime_grp',
    'app_readonly_grp',
    'app_backup_grp'
)
ORDER BY grantee, table_name, privilege_type;

-- 5. Verify login roles and group roles
SELECT
    rolname,
    rolcanlogin,
    rolsuper
FROM pg_roles
WHERE rolname IN (
    'app_runtime_grp',
    'app_readonly_grp',
    'app_backup_grp',
    'campussafe_app',
    'campussafe_report',
    'campussafe_backup'
)
ORDER BY rolname;

-- 6. Verify role memberships
SELECT
    member.rolname AS login_role,
    parent.rolname AS group_role
FROM pg_auth_members m
JOIN pg_roles parent ON parent.oid = m.roleid
JOIN pg_roles member ON member.oid = m.member
WHERE parent.rolname IN (
    'app_runtime_grp',
    'app_readonly_grp',
    'app_backup_grp'
)
ORDER BY login_role;