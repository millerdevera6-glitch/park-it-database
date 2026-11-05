
-- BOARDTRACK: CREATE DATABASE ROLES

-- Group roles
CREATE ROLE boardtrack_admin_grp NOLOGIN;
CREATE ROLE app_runtime_grp NOLOGIN;
CREATE ROLE app_readonly_grp NOLOGIN;

-- Application runtime login
-- Replace the placeholder with a secure password.
CREATE ROLE boardtrack_app
LOGIN
PASSWORD 'CHANGE_THIS_PASSWORD';

-- Assign runtime group membership
GRANT app_runtime_grp TO boardtrack_app;
