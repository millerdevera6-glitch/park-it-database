-- ============================================================================
-- CONTROLLED RECOVERY SIMULATION SCRIPT
-- Course: COMP 018 – Database Administration (Activity 6)
-- Target Staging Database: boardtrack_db_activity6_restore_test
-- Target Recovery Database: boardtrack_db_activity6_recovery_test
-- Safety Rules: Never touch original database; use disposable test records only.
-- ============================================================================

\echo '============================================================================'
\echo '  BOARDTRACK CONTROLLED RECOVERY SIMULATION'
\echo '============================================================================'

-- ----------------------------------------------------------------------------
-- STEP 1: PROVISION DEDICATED DISPOSABLE TEST RECORD
-- Note: To prevent destroying genuine application data, we insert a distinct,
-- traceable test payment on Lease #1.
-- ----------------------------------------------------------------------------
\echo '\n[STEP 1] Inserting Disposable Test Record into Restored Test Database...'

INSERT INTO payment (lease_id, payment_date, amount, payment_method, status)
VALUES (1, CURRENT_DATE, 999.99, 'CASH', 'COMPLETED')
RETURNING payment_id, lease_id, payment_date, amount, payment_method, status;

-- ----------------------------------------------------------------------------
-- STEP 2: RECORD PRE-INCIDENT STATE
-- ----------------------------------------------------------------------------
\echo '\n[STEP 2] Recording Pre-Incident State of Test Record...'
SELECT 
    payment_id,
    lease_id,
    payment_date,
    amount,
    payment_method,
    status
FROM payment 
WHERE amount = 999.99 AND payment_method = 'CASH';

-- ----------------------------------------------------------------------------
-- STEP 3: SIMULATE ACCIDENTAL DATA LOSS INCIDENT
-- ----------------------------------------------------------------------------
\echo '\n[STEP 3] Simulating Accidental Human Error / Application Deletion...'
DELETE FROM payment 
WHERE amount = 999.99 AND payment_method = 'CASH'
RETURNING payment_id, 'DELETED' AS incident_status;

-- ----------------------------------------------------------------------------
-- STEP 4: VERIFY RECORD DELETION / CORRUPTION IN ACTIVE STAGING
-- ----------------------------------------------------------------------------
\echo '\n[STEP 4] Verifying Record is Missing from Active Staging Database...'
SELECT 
    COUNT(*) AS records_found,
    CASE WHEN COUNT(*) = 0 THEN 'CONFIRMED MISSING / INCIDENT ACTIVE' ELSE 'RECORD STILL EXISTS' END AS verification_status
FROM payment 
WHERE amount = 999.99 AND payment_method = 'CASH';

-- ----------------------------------------------------------------------------
-- STEP 5: RESTORATION TO DEDICATED RECOVERY DATABASE
-- (Executed via command line: createdb & pg_restore into boardtrack_db_activity6_recovery_test)
-- ----------------------------------------------------------------------------
\echo '\n[STEP 5] Database Administrator provisions recovery database:'
\echo '  createdb -U postgres -h localhost -p 5432 boardtrack_db_activity6_recovery_test'
\echo '  pg_restore -U postgres -h localhost -p 5432 -d boardtrack_db_activity6_recovery_test boardtrack_activity6.dump'

-- ----------------------------------------------------------------------------
-- STEP 6: VERIFY CANONICAL RESTORATION & EXTRACT RECOVERED STATE
-- (Run against boardtrack_db_activity6_recovery_test)
-- ----------------------------------------------------------------------------
\echo '\n[STEP 6] Querying Canonical Seed Baseline in Recovered Database...'
SELECT 
    payment_id,
    lease_id,
    payment_date,
    amount,
    payment_method,
    status
FROM payment
ORDER BY payment_id;

\echo '\n[STEP 7] Verifying Referential Integrity of Recovered Payment & Lease...'
SELECT 
    p.payment_id,
    p.lease_id,
    t.full_name AS tenant_name,
    pr.property_name,
    r.room_number,
    p.amount,
    p.status AS payment_status
FROM payment p
JOIN lease l ON p.lease_id = l.lease_id
JOIN tenant t ON l.tenant_id = t.tenant_id
JOIN room r ON l.room_id = r.room_id
JOIN property pr ON r.property_id = pr.property_id
ORDER BY p.payment_id;

\echo '============================================================================'
\echo '  END OF RECOVERY SIMULATION SCRIPT'
\echo '============================================================================'

