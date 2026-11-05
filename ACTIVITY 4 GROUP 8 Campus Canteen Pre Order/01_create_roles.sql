-- Create group roles
CREATE ROLE canteen_app_grp NOLOGIN;
CREATE ROLE canteen_readonly_grp NOLOGIN;

-- Create application login
CREATE ROLE canteen_app
LOGIN
PASSWORD 'CHANGE_THIS_PASSWORD'
IN ROLE canteen_app_grp;