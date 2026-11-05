-- Check database roles
SELECT rolname, rolsuper, rolcanlogin
FROM pg_roles
WHERE rolname IN (
    'canteen_admin',
    'canteen_app',
    'canteen_app_grp',
    'canteen_readonly_grp'
);

-- Check table permissions
SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN (
    'canteen_app_grp',
    'canteen_readonly_grp'
)
ORDER BY grantee, table_name, privilege_type;

-- Check application membership
SELECT pg_has_role(
    'canteen_app',
    'canteen_app_grp',
    'MEMBER'
);