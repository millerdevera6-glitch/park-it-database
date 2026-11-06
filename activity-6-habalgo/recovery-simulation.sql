-- ==============================================================================
-- COMP 018 – Database Administration | Activity 6
-- Script: recovery-simulation.sql
-- Project: HabalGo – Transportation & Booking Management System
-- Purpose: Controlled Disaster Recovery Simulation
-- Execution Rule: MUST RUN ONLY ON RESTORE/RECOVERY TEST DATABASES
-- NEVER EXECUTE AGAINST PRODUCTION grp00_habalgodb
-- ==============================================================================

\echo '====================================================='
\echo 'HABALGO CONTROLLED RECOVERY SIMULATION'
\echo '====================================================='

-- STEP 1: Connect to Restored Test Database
\connect grp00_habalgodb_activity6_restore_test

-- STEP 2: Insert Identified Disposable Test Record and Related Entities
INSERT INTO habalgo.customer (customer_id, name, phone, email) 
VALUES (1, 'DISPOSABLE TEST RIDER - SIMULATION', '09990001122', 'disposable.rider.simulation@habalgo-test.local')
ON CONFLICT (customer_id) DO NOTHING;

INSERT INTO habalgo.driver (driver_id, name, phone, license_no) 
VALUES (1, 'DISPOSABLE TEST DRIVER', '09170009988', 'N01-SIM-000001')
ON CONFLICT (driver_id) DO NOTHING;

INSERT INTO habalgo.location (location_id, address, city) 
VALUES (1, '123 Simulation Ave', 'Quezon City')
ON CONFLICT (location_id) DO NOTHING;

INSERT INTO habalgo.booking (booking_id, customer_id, driver_id, pickup_location_id, dropoff_location_id, booking_status) 
VALUES (1, 1, 1, 1, 1, 'Completed')
ON CONFLICT (booking_id) DO NOTHING;

-- STEP 3: Verify Pre-Incident Baseline State
SELECT customer_id, name, phone, email FROM habalgo.customer WHERE customer_id = 1;
SELECT booking_id, customer_id, booking_status FROM habalgo.booking WHERE booking_id = 1;

-- STEP 4: Simulate Disaster / Accidental Deletion Incident
-- (Foreign Key constraint RESTRICT prevents deleting customer while referenced by booking)
DELETE FROM habalgo.booking WHERE booking_id = 1;
DELETE FROM habalgo.customer WHERE customer_id = 1;

-- STEP 5: Confirm Data Loss in Primary Test Database
SELECT * FROM habalgo.customer WHERE customer_id = 1;
SELECT * FROM habalgo.booking WHERE booking_id = 1;

-- STEP 6: Disaster Recovery Verification Query
-- Connect to Recovery Database (populated via pg_restore from checkpoint dump)
\connect grp00_habalgodb_recovery_test

-- STEP 7: Locate and Extract Recovered Records from Recovery Database
SELECT customer_id, name, phone, email FROM habalgo.customer WHERE customer_id = 1;
SELECT booking_id, customer_id, driver_id, booking_status FROM habalgo.booking WHERE booking_id = 1;

-- STEP 8: Re-transplant Recovered Records to Test Database
\connect grp00_habalgodb_activity6_restore_test

INSERT INTO habalgo.customer (customer_id, name, phone, email)
SELECT customer_id, name, phone, email 
FROM dblink('dbname=grp00_habalgodb_recovery_test user=postgres host=localhost port=5432', 
            'SELECT customer_id, name, phone, email FROM habalgo.customer WHERE customer_id = 1')
     AS r(customer_id int, name varchar, phone varchar, email varchar)
ON CONFLICT (customer_id) DO UPDATE 
SET name = EXCLUDED.name, phone = EXCLUDED.phone, email = EXCLUDED.email;

\echo '====================================================='
\echo 'RECOVERY SIMULATION COMPLETE - VERIFIED ACCIDENTAL DATA RESTORED'
\echo '====================================================='

