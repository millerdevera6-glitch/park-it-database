
-- BOARDTRACK: VERIFY DATABASE PERMISSIONS

-- 1. Check created roles
SELECT rolname, rolcanlogin
FROM pg_roles
WHERE rolname IN (
    'boardtrack_owner',
    'boardtrack_admin_grp',
    'app_runtime_grp',
    'app_readonly_grp',
    'boardtrack_app'
);

-- 2. Check table privileges
SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN (
    'boardtrack_admin_grp',
    'app_runtime_grp',
    'app_readonly_grp'
)
ORDER BY table_name, grantee, privilege_type;

-- 3. Check role membership
SELECT
    member.rolname AS member,
    granted.rolname AS granted_role
FROM pg_auth_members m
JOIN pg_roles member ON member.oid = m.member
JOIN pg_roles granted ON granted.oid = m.roleid
WHERE member.rolname = 'boardtrack_app';

-- 4. Check runtime DELETE permission
SELECT
    has_table_privilege(
        'app_runtime_grp',
        format('%I.%I', schemaname, tablename),
        'DELETE'
    ) AS can_delete,
    schemaname,
    tablename
FROM pg_tables
WHERE schemaname = 'public';
