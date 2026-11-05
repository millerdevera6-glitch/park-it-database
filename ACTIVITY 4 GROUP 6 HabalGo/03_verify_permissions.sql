
-- ACTIVITY 4: HABALGO
-- FILE 3: VERIFY PERMISSIONS

-- Check schema access
SELECT
    has_schema_privilege(
        'habalgo_admin', 'habalgo', 'USAGE'
    ) AS admin_access,

    has_schema_privilege(
        'habalgo_app', 'habalgo', 'USAGE'
    ) AS app_access,

    has_schema_privilege(
        'habalgo_auditor', 'habalgo', 'USAGE'
    ) AS auditor_access;


-- Check table permissions
SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'habalgo'
ORDER BY grantee, table_name, privilege_type;


-- Check application permissions
SELECT
    has_table_privilege(
        'habalgo_app',
        'habalgo.booking',
        'INSERT'
    ) AS app_can_insert,

    has_table_privilege(
        'habalgo_app',
        'habalgo.booking',
        'DELETE'
    ) AS app_can_delete;


-- Check auditor permissions
SELECT
    has_table_privilege(
        'habalgo_auditor',
        'habalgo.booking',
        'SELECT'
    ) AS auditor_can_read,

    has_table_privilege(
        'habalgo_auditor',
        'habalgo.booking',
        'UPDATE'
    ) AS auditor_can_update;
