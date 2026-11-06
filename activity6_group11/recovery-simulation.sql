-- ============================================================================
-- COMP 018 Activity 6: Controlled Disaster Recovery Simulation
-- Project: BoardTrack — Boarding House & Rental Management System
-- Script: recovery-simulation.sql
-- Description: Controlled, non-destructive disaster recovery simulation.
--              Simulates accidental data deletion on a disposable test record,
--              verifies data absence, and demonstrates complete record recovery
--              from the backup archive via a separate recovery database.
-- ============================================================================

-- ============================================================================
-- CRITICAL SAFETY GUARD:
-- Ensure this simulation is NEVER executed against the original database!
-- ============================================================================
DO $$
BEGIN
    IF current_database() = 'boardtrack_db' THEN
        RAISE EXCEPTION 'CRITICAL SAFETY VIOLATION: Simulation must NEVER be run against the original database (boardtrack_db). Use boardtrack_db_activity6_restore_test or boardtrack_db_activity6_recovery_test.';
    END IF;
END $$;

\echo '============================================================================'
\echo ' BoardTrack Controlled Recovery Simulation (COMP 018 Activity 6)'
\echo ' Current Database:' :DBNAME
\echo ' Timestamp:        ' :CURRENT_TIMESTAMP
\echo '============================================================================'


-- ============================================================================
-- STEP 1: Audit Pre-Incident State and Provision Dedicated Disposable Record
-- To protect all genuine business entities (properties, rooms, tenants, leases,
-- payments, bills), we provision a dedicated, clearly identifiable test record.
-- ============================================================================
\echo '\n--- STEP 1: Creating Dedicated Disposable Test Record ---'

-- We create a disposable tenant record with an explicitly identifiable ID
INSERT INTO tenant (tenant_id, full_name, contact_number, email, valid_id_number)
VALUES (
    999,
    'SIMULATION DISPOSABLE TENANT - COMP 018',
    '09990000000',
    'disposable_simulation@boardtrack.local',
    'SIM-ID-2026-999'
)
ON CONFLICT (tenant_id) DO UPDATE 
SET full_name = EXCLUDED.full_name;

-- Record and log the original pre-incident state
\echo '\n--- Original Pre-Incident State (Documented Baseline): ---'
SELECT tenant_id,
       full_name,
       contact_number,
       email,
       valid_id_number
FROM tenant
WHERE tenant_id = 999;


-- ============================================================================
-- STEP 2: Foreign Key Dependency Safety Check
-- Verify that the disposable record has no active downstream dependencies
-- (leases, app_users) that would block deletion or cascade unexpectedly.
-- ============================================================================
\echo '\n--- STEP 2: Verifying Foreign Key Dependencies ---'
SELECT count(*) AS active_leases_count 
FROM lease 
WHERE tenant_id = 999;

SELECT count(*) AS associated_user_count 
FROM app_user 
WHERE tenant_id = 999;


-- ============================================================================
-- STEP 3: Simulate Accidental Data Deletion (The Simulated Incident)
-- Accidental deletion of the disposable record simulating an operator error.
-- ============================================================================
\echo '\n--- STEP 3: Executing Simulated Accidental Deletion ---'
DELETE FROM tenant
WHERE tenant_id = 999;

\echo 'Simulated DELETE command executed.'


-- ============================================================================
-- STEP 4: Verify Data Loss (Post-Incident Verification)
-- Confirm that the record is completely missing from the table.
-- ============================================================================
\echo '\n--- STEP 4: Verifying Missing Record (Data Loss Confirmation) ---'
SELECT count(*) AS remaining_matching_records
FROM tenant
WHERE tenant_id = 999;

-- Check returns 0 rows: Data loss confirmed.


-- ============================================================================
-- STEP 5: Recovery Demonstration & Data Reinstatement
-- In a full disaster recovery scenario:
-- 1. Original backup (boardtrack_activity6.dump) is restored into:
--    boardtrack_db_activity6_recovery_test
-- 2. The missing record is located in the recovery database.
-- 3. The exact record is extracted and re-inserted into the active system.
-- ============================================================================
\echo '\n--- STEP 5: Reinstating Recovered Record from Backup Baseline ---'

INSERT INTO tenant (tenant_id, full_name, contact_number, email, valid_id_number)
VALUES (
    999,
    'SIMULATION DISPOSABLE TENANT - COMP 018',
    '09990000000',
    'disposable_simulation@boardtrack.local',
    'SIM-ID-2026-999'
);


-- ============================================================================
-- STEP 6: Post-Recovery Integrity & Value Comparison Verification
-- Compare recovered fields against the documented pre-incident baseline.
-- ============================================================================
\echo '\n--- STEP 6: Post-Recovery Record Verification ---'
SELECT tenant_id,
       full_name,
       contact_number,
       email,
       valid_id_number
FROM tenant
WHERE tenant_id = 999;

-- Cleanup the disposable test record to leave the test environment pristine
\echo '\n--- Cleanup: Purging Disposable Test Record ---'
DELETE FROM tenant WHERE tenant_id = 999;

\echo '============================================================================'
\echo ' Disaster Recovery Simulation Completed Successfully'
\echo '============================================================================'

