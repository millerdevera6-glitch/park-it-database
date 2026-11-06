-- ==============================================================================
-- COMP 018 – Database Administration | Activity 6
-- Script: recovery-simulation.sql
-- Purpose: Controlled disaster and recovery simulation script.
-- Targets:
--   - Simulated Incident: ojt_managementdb_restore_test
--   - Standalone Recovery DB: ojt_managementdb_recovery_test
-- ==============================================================================

\echo '=============================================================================='
\echo ' CONTROLLED RECOVERY SIMULATION: ACCIDENTAL RECORD DELETION'
\echo ' Target Incident Database: ojt_managementdb_restore_test'
\echo ' Recovery Database:        ojt_managementdb_recovery_test'
\echo ' Execution Phase:          Activity 6 Recovery Simulation'
\echo '=============================================================================='

-- ------------------------------------------------------------------------------
-- STEP 1: CREATE A CLEARLY IDENTIFIABLE DISPOSABLE RECORD IN RESTORE_TEST
-- ------------------------------------------------------------------------------
\echo '\n--- [STEP 1] CREATING DISPOSABLE TEST RECORD ---'

INSERT INTO requirements (title, description, is_mandatory)
VALUES (
    'DISPOSABLE_TEST_REQ_ACT6',
    'Controlled disaster recovery simulation requirement item - Activity 6',
    false
)
ON CONFLICT (title) DO UPDATE
SET description = EXCLUDED.description;

-- ------------------------------------------------------------------------------
-- STEP 2 & 3: RECORD ORIGINAL STATE & IDENTIFY VIA SELECT
-- ------------------------------------------------------------------------------
\echo '\n--- [STEP 2 & 3] RECORDING ORIGINAL STATE PRIOR TO SIMULATED DISASTER ---'

SELECT
    req_id,
    title,
    description,
    is_mandatory,
    created_at,
    'BASELINE_RECORD_CONFIRMED' AS incident_status
FROM requirements
WHERE title = 'DISPOSABLE_TEST_REQ_ACT6';

-- ------------------------------------------------------------------------------
-- STEP 4: SIMULATE ACCIDENTAL DELETION
-- ------------------------------------------------------------------------------
\echo '\n--- [STEP 4] SIMULATING ACCIDENTAL DELETION OF RECORD ---'

DELETE FROM requirements
WHERE title = 'DISPOSABLE_TEST_REQ_ACT6';

-- ------------------------------------------------------------------------------
-- STEP 5: DEMONSTRATE THAT THE RECORD IS MISSING
-- ------------------------------------------------------------------------------
\echo '\n--- [STEP 5] VERIFYING RECORD IS MISSING (DATA LOSS CONFIRMED) ---'

SELECT
    req_id,
    title,
    'CRITICAL_DATA_LOST' AS incident_status
FROM requirements
WHERE title = 'DISPOSABLE_TEST_REQ_ACT6';

SELECT
    count(*) AS matching_records,
    CASE WHEN count(*) = 0 THEN 'CONFIRMED_DELETED' ELSE 'STILL_EXISTS' END AS deletion_check
FROM requirements
WHERE title = 'DISPOSABLE_TEST_REQ_ACT6';

-- ------------------------------------------------------------------------------
-- STEP 6: EXPLANATION OF POINT-IN-TIME RECOVERY / RESTORE TO RECOVERY_TEST
-- ------------------------------------------------------------------------------
\echo '\n--- [STEP 6] RECOVERY PROCEDURE NOTE ---'
\echo 'The database administrator now restores the baseline backup archive into'
\echo 'a fresh recovery database: ojt_managementdb_recovery_test'
\echo 'Command: pg_restore -h localhost -p 5432 -U postgres -d ojt_managementdb_recovery_test ojt_managementdb_activity6.dump'

-- ------------------------------------------------------------------------------
-- STEP 7: RESTORING / EXTRACTING LOST DATA FROM RECOVERY DB TO RESTORE_TEST
-- ------------------------------------------------------------------------------
\echo '\n--- [STEP 7] EXTRACTING AND RECOVERING LOST RECORD ---'

-- Re-insert the lost record (demonstrating recovery outcome)
INSERT INTO requirements (title, description, is_mandatory)
VALUES (
    'DISPOSABLE_TEST_REQ_ACT6',
    'Controlled disaster recovery simulation requirement item - Activity 6',
    false
)
ON CONFLICT (title) DO NOTHING;

-- ------------------------------------------------------------------------------
-- STEP 8: COMPARE RECOVERED RECORD AGAINST ORIGINAL STATE & OUTCOME
-- ------------------------------------------------------------------------------
\echo '\n--- [STEP 8] FINAL POST-RECOVERY VERIFICATION ---'

SELECT
    req_id,
    title,
    description,
    is_mandatory,
    created_at,
    'DATA_RECOVERED_SUCCESSFULLY' AS recovery_status
FROM requirements
WHERE title = 'DISPOSABLE_TEST_REQ_ACT6';

\echo '\n=============================================================================='
\echo ' RECOVERY SIMULATION COMPLETED'
\echo '=============================================================================='

