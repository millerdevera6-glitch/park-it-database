
-- ACTIVITY 4: VERIFY DATABASE ROLES

-- Check created roles
SELECT rolname, rolcanlogin
FROM pg_roles
WHERE rolname IN (
    'ojt_admin',
    'ojt_coordinator',
    'academic_supervisor',
    'company_supervisor',
    'ojt_student'
);

-- Check database permissions
SELECT
    grantee,
    privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
ORDER BY grantee, table_name;
