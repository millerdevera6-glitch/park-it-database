-- BREWPOS: CREATE DATABASE ROLES

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'app_admin_grp'
    ) THEN
        CREATE ROLE app_admin_grp NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'app_runtime_grp'
    ) THEN
        CREATE ROLE app_runtime_grp NOLOGIN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles
        WHERE rolname = 'app_readonly_grp'
    ) THEN
        CREATE ROLE app_readonly_grp NOLOGIN;
    END IF;
END
$$;