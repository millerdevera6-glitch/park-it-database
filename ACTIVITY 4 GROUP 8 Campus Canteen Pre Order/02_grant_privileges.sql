-- Allow application and read-only roles to connect
GRANT CONNECT ON DATABASE canteen_db
TO canteen_app_grp, canteen_readonly_grp;

-- Allow access to the public schema
GRANT USAGE ON SCHEMA public
TO canteen_app_grp, canteen_readonly_grp;

-- Application permissions
GRANT SELECT, INSERT, UPDATE
ON ALL TABLES IN SCHEMA public
TO canteen_app_grp;

-- Allow deletion only on menu_item
GRANT DELETE
ON TABLE public.menu_item
TO canteen_app_grp;

-- Allow sequence usage
GRANT USAGE
ON ALL SEQUENCES IN SCHEMA public
TO canteen_app_grp;

-- Read-only permissions
GRANT SELECT
ON ALL TABLES IN SCHEMA public
TO canteen_readonly_grp;