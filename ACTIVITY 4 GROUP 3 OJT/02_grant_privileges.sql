
-- ACTIVITY 4: DATABASE ACCESS

GRANT CONNECT ON DATABASE ojt_managementdb
TO ojt_admin,
   ojt_coordinator,
   academic_supervisor,
   company_supervisor,
   ojt_student;

-- Allow access to the public schema
GRANT USAGE ON SCHEMA public
TO ojt_admin,
   ojt_coordinator,
   academic_supervisor,
   company_supervisor,
   ojt_student;

-- Administrator receives full access to existing tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public
TO ojt_admin;

-- Allow administrator to use existing sequences
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public
TO ojt_admin;
