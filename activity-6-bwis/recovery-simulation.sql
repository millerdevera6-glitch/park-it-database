-- ============================================================================
-- BWIS IT SOLUTIONS - CAMPUS CANTEEN PRE-ORDER & QUEUE MANAGEMENT SYSTEM
-- COMP 018 ACTIVITY 6: CONTROLLED RECOVERY SIMULATION SCRIPT
-- Environments:
--   Primary Test DB    : canteendb_activity6_restore_test (simulated data loss target)
--   Recovery Target DB : canteendb_activity6_recovery_test (restored recovery target)
-- Safety: Never targets original production database (canteendb).
-- ============================================================================

\echo '======================================================================'
\echo 'STEP 1: INSPECT BEFORE-STATE OF DISPOSABLE MARKER IN RESTORE TEST DB'
\echo '======================================================================'
-- Target: canteendb_activity6_restore_test
SELECT 
    vendor_id, 
    vendor_name, 
    contact_number, 
    email, 
    is_active
FROM public.vendor 
WHERE email = 'disposable_vendor@recovery.test';

\echo '----------------------------------------------------------------------'
\echo 'STEP 2: CAPTURE BEFORE-STATE JSON ENCODING FOR FINGERPRINTING'
\echo '----------------------------------------------------------------------'
SELECT row_to_json(v)::text AS before_state_json
FROM (
    SELECT vendor_id, vendor_name, contact_number, email, is_active 
    FROM public.vendor 
    WHERE email = 'disposable_vendor@recovery.test'
) v;

\echo '----------------------------------------------------------------------'
\echo 'STEP 3: SIMULATE ACCIDENTAL DATA LOSS (ACCIDENTAL DELETE)'
\echo '----------------------------------------------------------------------'
DELETE FROM public.vendor 
WHERE email = 'disposable_vendor@recovery.test';

\echo '----------------------------------------------------------------------'
\echo 'STEP 4: CONFIRM DISPOSABLE RECORD IS MISSING (COUNT MUST BE 0)'
\echo '----------------------------------------------------------------------'
SELECT count(*) AS remaining_marker_count
FROM public.vendor 
WHERE email = 'disposable_vendor@recovery.test';

\echo '======================================================================'
\echo 'STEP 5: RECOVERY VERIFICATION (RUN CONNECTED TO RECOVERY TARGET DB)'
\echo 'Target: canteendb_activity6_recovery_test'
\echo '======================================================================'
-- Once pg_restore restores bwis_recovery_snapshot.dump into canteendb_activity6_recovery_test:
-- Run:
-- \c canteendb_activity6_recovery_test
-- SELECT row_to_json(v)::text AS recovered_state_json
-- FROM (
--     SELECT vendor_id, vendor_name, contact_number, email, is_active 
--     FROM public.vendor 
--     WHERE email = 'disposable_vendor@recovery.test'
-- ) v;

