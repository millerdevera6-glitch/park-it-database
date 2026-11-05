-- CHECK DATABASE ROLES
SELECT rolname
FROM pg_roles
WHERE rolname IN (
    'app_admin_grp',
    'app_runtime_grp',
    'app_readonly_grp'
);

-- CHECK TABLE PERMISSIONS
SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN (
    'app_admin_grp',
    'app_runtime_grp',
    'app_readonly_grp'
)
ORDER BY grantee, table_name, privilege_type;