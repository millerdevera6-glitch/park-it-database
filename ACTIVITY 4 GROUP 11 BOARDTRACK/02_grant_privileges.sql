
-- BOARDTRACK: GRANT DATABASE PRIVILEGES

-- Allow access to the public schema
GRANT USAGE ON SCHEMA public
TO boardtrack_admin_grp, app_runtime_grp, app_readonly_grp;

-- Administrator: Full access to existing tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public
TO boardtrack_admin_grp;

-- Staff/application runtime: No DELETE privilege
GRANT SELECT, INSERT, UPDATE
ON ALL TABLES IN SCHEMA public
TO app_runtime_grp;

-- Tenant/read-only access
GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO app_readonly_grp;

-- Sequence permissions for inserting records
GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA public
TO app_runtime_grp;

-- Sequence permissions for administrators
GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA public
TO boardtrack_admin_grp;
