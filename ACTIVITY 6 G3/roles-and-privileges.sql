-- ==============================================================================
-- COMP 018 – Database Administration | Activity 6
-- Script: roles-and-privileges.sql
-- Purpose: Re-create PostgreSQL login roles and assign least-privilege
--          permissions for the OJT Management System.
-- Note: Designed to be idempotent (safe to run multiple times).
-- ==============================================================================

-- 1. Create Roles if they do not exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'ojt_admin') THEN
        CREATE ROLE ojt_admin WITH LOGIN PASSWORD 'Admin@Ojt2026';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'ojt_student') THEN
        CREATE ROLE ojt_student WITH LOGIN PASSWORD 'Student@Ojt2026';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'ojt_academic_supervisor') THEN
        CREATE ROLE ojt_academic_supervisor WITH LOGIN PASSWORD 'Academic@Ojt2026';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'ojt_company_supervisor') THEN
        CREATE ROLE ojt_company_supervisor WITH LOGIN PASSWORD 'Company@Ojt2026';
    END IF;

    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'ojt_coordinator') THEN
        CREATE ROLE ojt_coordinator WITH LOGIN PASSWORD 'Coord@Ojt2026';
    END IF;
END
$$;

-- 2. Schema USAGE grants
GRANT USAGE ON SCHEMA public TO
    ojt_admin,
    ojt_student,
    ojt_academic_supervisor,
    ojt_company_supervisor,
    ojt_coordinator;

-- 3. ADMIN PRIVILEGES
GRANT SELECT, INSERT, UPDATE ON users TO ojt_admin;
GRANT SELECT ON audit_log TO ojt_admin;
GRANT USAGE, SELECT ON SEQUENCE users_user_id_seq TO ojt_admin;

-- 4. STUDENT PRIVILEGES
GRANT SELECT ON
    students,
    companies,
    requirements,
    ojt_applications,
    student_requirements,
    ojt_placements,
    attendance,
    evaluations
TO ojt_student;

GRANT INSERT, UPDATE ON
    ojt_applications,
    student_requirements,
    attendance
TO ojt_student;

GRANT USAGE, SELECT ON SEQUENCE
    ojt_applications_application_id_seq,
    student_requirements_student_req_id_seq,
    attendance_attendance_id_seq
TO ojt_student;

-- 5. ACADEMIC SUPERVISOR PRIVILEGES
GRANT SELECT ON
    students,
    ojt_applications,
    student_requirements,
    ojt_placements,
    attendance,
    evaluations,
    requirements
TO ojt_academic_supervisor;

GRANT UPDATE (
    verified_by_sup_id,
    status,
    verified_at,
    remarks
) ON student_requirements TO ojt_academic_supervisor;

GRANT UPDATE (status) ON ojt_placements TO ojt_academic_supervisor;
GRANT UPDATE (is_verified) ON attendance TO ojt_academic_supervisor;

-- 6. COMPANY SUPERVISOR PRIVILEGES
GRANT SELECT ON
    students,
    companies,
    company_supervisors,
    ojt_placements,
    attendance,
    evaluations
TO ojt_company_supervisor;

GRANT INSERT, UPDATE ON attendance TO ojt_company_supervisor;
GRANT INSERT, UPDATE ON evaluations TO ojt_company_supervisor;

GRANT USAGE, SELECT ON SEQUENCE
    attendance_attendance_id_seq,
    evaluations_evaluation_id_seq
TO ojt_company_supervisor;

-- 7. OJT COORDINATOR PRIVILEGES
GRANT SELECT ON
    students,
    companies,
    academic_supervisors,
    company_supervisors,
    ojt_applications,
    student_requirements,
    ojt_placements,
    attendance,
    evaluations,
    requirements
TO ojt_coordinator;

GRANT INSERT, UPDATE ON
    companies,
    company_supervisors,
    ojt_applications,
    ojt_placements
TO ojt_coordinator;

GRANT USAGE, SELECT ON SEQUENCE
    companies_company_id_seq,
    company_supervisors_company_sup_id_seq,
    ojt_applications_application_id_seq,
    ojt_placements_placement_id_seq
TO ojt_coordinator;

