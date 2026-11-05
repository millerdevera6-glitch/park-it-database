
-- ACTIVITY 4: CREATE DATABASE ROLES

-- Administrator
CREATE ROLE ojt_admin NOLOGIN;

-- OJT Coordinator
CREATE ROLE ojt_coordinator NOLOGIN;

-- Academic Supervisor
CREATE ROLE academic_supervisor NOLOGIN;

-- Company Supervisor
CREATE ROLE company_supervisor NOLOGIN;

-- Student
CREATE ROLE ojt_student NOLOGIN;

-- Check created roles
SELECT rolname
FROM pg_roles
WHERE rolname IN (
    'ojt_admin',
    'ojt_coordinator',
    'academic_supervisor',
    'company_supervisor',
    'ojt_student'
);
