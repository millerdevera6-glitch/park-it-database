-- BREWPOS: GRANT DATABASE PRIVILEGES

-- Database access
GRANT CONNECT ON DATABASE grp_brewposdb
TO app_admin_grp, app_runtime_grp, app_readonly_grp;

GRANT USAGE ON SCHEMA public
TO app_admin_grp, app_runtime_grp, app_readonly_grp;

-- MANAGER: Manage menu and view sales
GRANT SELECT ON public.staff TO app_admin_grp;

GRANT SELECT, INSERT, UPDATE, DELETE
ON public.menu_category, public.menu_item
TO app_admin_grp;

GRANT SELECT
ON public.order_ticket, public.order_line_item
TO app_admin_grp;

-- CASHIER: Process customer orders
GRANT SELECT
ON public.staff, public.menu_category, public.menu_item
TO app_runtime_grp;

GRANT SELECT, INSERT
ON public.order_ticket, public.order_line_item
TO app_runtime_grp;

-- AUDITOR: Read-only access
GRANT SELECT ON ALL TABLES IN SCHEMA public
TO app_readonly_grp;

-- Required sequence permissions
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public
TO app_admin_grp, app_runtime_grp;