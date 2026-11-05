
-- ACTIVITY 4: HABALGO
-- FILE 2: GRANT PRIVILEGES

-- Allow accounts to access the schema
GRANT USAGE ON SCHEMA habalgo
TO habalgo_admin, habalgo_app, habalgo_auditor;

-- ADMIN: Full access to existing tables
GRANT ALL PRIVILEGES
ON ALL TABLES IN SCHEMA habalgo
TO habalgo_admin;

-- ADMIN: Access to ID sequences
GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA habalgo
TO habalgo_admin;

-- APPLICATION: Read and modify records
GRANT SELECT, INSERT, UPDATE
ON ALL TABLES IN SCHEMA habalgo
TO habalgo_app;

-- APPLICATION: Use ID sequences
GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA habalgo
TO habalgo_app;

-- AUDITOR: Read-only access
GRANT SELECT
ON ALL TABLES IN SCHEMA habalgo
TO habalgo_auditor;
