-- ==============================================================================
-- PUP-SPOT Campus Lost and Found System
-- COMP 018 - Database Administration | Activity 6
-- Script: recovery-simulation.sql - Controlled Disaster Recovery Simulation
-- ==============================================================================

\echo '================================================================='
\echo '    PUP-SPOT CONTROLLED RECOVERY SIMULATION (ACTIVITY 6)         '
\echo '================================================================='
\echo ''
\echo 'SAFETY NOTICE: This simulation executes EXCLUSIVELY against disposable'
\echo 'test databases (grp05_lostandfounddb_restore_test and grp05_lostandfounddb_recovery_test).'
\echo 'The primary production database (grp05_lostandfounddb) is NEVER touched.'
\echo ''

-- -----------------------------------------------------------------------------
-- STEP 1: Inspect and Record Target Disposable Record (Pre-Incident State)
-- Target: potential_matches match_id = 5
-- Justification: Demonstration matching record with no inbound foreign keys.
-- -----------------------------------------------------------------------------
\echo '--- [STEP 1] Recording Pre-Incident Values of Disposable Record (match_id = 5) ---'
SELECT 
    match_id, 
    report_id, 
    item_id, 
    similarity_score, 
    created_at
FROM potential_matches
WHERE match_id = 5;

-- -----------------------------------------------------------------------------
-- STEP 2: Simulate Accidental Data Deletion (Simulated Incident)
-- -----------------------------------------------------------------------------
\echo ''
\echo '--- [STEP 2] Simulating Accidental Deletion Incident ---'
DELETE FROM potential_matches 
WHERE match_id = 5;

-- -----------------------------------------------------------------------------
-- STEP 3: Verify the Incident (Confirm Record is Missing)
-- -----------------------------------------------------------------------------
\echo ''
\echo '--- [STEP 3] Verifying Record Absence in grp05_lostandfounddb_restore_test ---'
SELECT 
    count(*) AS current_match_count,
    CASE WHEN count(*) = 5 THEN 'CONFIRMED MISSING (SIMULATED DATA LOSS)' ELSE 'UNEXPECTED COUNT' END AS incident_status
FROM potential_matches;

SELECT * FROM potential_matches WHERE match_id = 5;

-- -----------------------------------------------------------------------------
-- STEP 4: Recovery via Standby / Recovery Database
-- In production, the DBA restores the latest backup to grp05_lostandfounddb_recovery_test.
-- The query below verifies that the record was preserved in the backup archive.
-- -----------------------------------------------------------------------------
\echo ''
\echo '--- [STEP 4] Querying Recovered State from Recovery Test Database ---'
\echo 'Connecting to grp05_lostandfounddb_recovery_test to locate the lost record...'
\c grp05_lostandfounddb_recovery_test

SELECT 
    match_id, 
    report_id, 
    item_id, 
    similarity_score, 
    created_at,
    'PRESERVED IN BACKUP ARCHIVE' AS archive_status
FROM potential_matches
WHERE match_id = 5;

-- -----------------------------------------------------------------------------
-- STEP 5: Surgical Re-insertion (Point-in-Time Item Restoration)
-- Demonstrates extracting the specific recovered record and restoring it
-- back into the active database without performing a full destructive overwrite.
-- -----------------------------------------------------------------------------
\echo ''
\echo '--- [STEP 5] Performing Surgical Record Re-Insertion into Restore Test DB ---'
\c grp05_lostandfounddb_restore_test

-- Insert the verified data recovered from the backup
INSERT INTO potential_matches (match_id, report_id, item_id, similarity_score, created_at)
VALUES (5, 1, 5, 61.25, '2026-11-05 16:08:51.39409')
ON CONFLICT (match_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- STEP 6: Final Post-Recovery Verification
-- -----------------------------------------------------------------------------
\echo ''
\echo '--- [STEP 6] Post-Recovery Verification in grp05_lostandfounddb_restore_test ---'
SELECT 
    match_id, 
    report_id, 
    item_id, 
    similarity_score, 
    created_at,
    'SUCCESSFULLY RECOVERED & RESTORED' AS recovery_status
FROM potential_matches
WHERE match_id = 5;

SELECT count(*) AS total_potential_matches FROM potential_matches;

\echo ''
\echo '================================================================='
\echo '          CONTROLLED RECOVERY SIMULATION COMPLETED               '
\echo '================================================================='

