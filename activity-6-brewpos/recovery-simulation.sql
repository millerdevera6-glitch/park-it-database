-- ==============================================================================
-- BrewPOS — Controlled Disaster Recovery Simulation Drill (recovery-simulation.sql)
-- Course   : COMP 018 — Database Administration
-- Project  : BrewPOS — Café Point-of-Sale System
-- Scenario : Accidental Deletion & Surgical Table-Level Recovery
-- Databases:
--   - Source / Production : grp_brewposdb (Preserved & Untouched)
--   - Staging Test DB     : grp_brewposdb_restore_test (Drill Target)
--   - Recovery Staging DB : grp_brewposdb_recovery_test (Fresh Restore from Dump)
-- ==============================================================================

-- -----------------------------------------------------------------------------
-- STEP 1: Pre-Incident Baseline State Inspection
-- Target: Disposable unreferenced menu item ('Pumpkin Spice Latte', item_id = 1)
-- Safety: Unreferenced by historical order_line_item rows, avoiding cascade corruption.
-- -----------------------------------------------------------------------------
\connect grp_brewposdb_restore_test

\echo '--- [STEP 1] Baseline Record Inspection in grp_brewposdb_restore_test ---'
SELECT item_id, category_id, item_name, price, is_active
FROM public.menu_item
WHERE item_id = 1;

-- Verify that foreign keys prevent accidental deletion of referenced items:
-- (e.g. Trying to delete item_id = 11 fails due to fk_order_line_item)
SELECT m.item_id, m.item_name, count(l.order_id) AS order_line_references
FROM public.menu_item m
LEFT JOIN public.order_line_item l ON l.item_id = m.item_id
WHERE m.item_id IN (1, 11)
GROUP BY m.item_id, m.item_name;

-- -----------------------------------------------------------------------------
-- STEP 2: Simulated Accidental Data-Loss Incident
-- Scenario: Operator runs an unconstrained or erroneous DELETE statement.
-- -----------------------------------------------------------------------------
\echo '\n--- [STEP 2] Simulating Accidental Human-Error Deletion ---'
DELETE FROM public.menu_item
WHERE item_id = 1;

-- -----------------------------------------------------------------------------
-- STEP 3: Incident Verification (Confirming Absence & Impact)
-- -----------------------------------------------------------------------------
\echo '\n--- [STEP 3] Verifying Data Loss in grp_brewposdb_restore_test ---'
SELECT count(*) AS remaining_menu_items,
       (SELECT count(*) FROM public.menu_item WHERE item_id = 1) AS missing_target_record
FROM public.menu_item;

-- -----------------------------------------------------------------------------
-- STEP 4: Recovery Database Provisioning & Dump Extraction
-- Note: Executed via PowerShell / Terminal:
--   createdb -U postgres -h localhost -p 5432 grp_brewposdb_recovery_test
--   pg_restore -U postgres -h localhost -p 5432 -d grp_brewposdb_recovery_test "C:\Users\Matt\pg_backups\brewpos\grp_brewposdb_activity6.dump"
-- -----------------------------------------------------------------------------
\connect grp_brewposdb_recovery_test

\echo '\n--- [STEP 4] Locating Original Record in Recovery Database ---'
SELECT item_id, category_id, item_name, price, is_active
FROM public.menu_item
WHERE item_id = 1;

-- -----------------------------------------------------------------------------
-- STEP 5: Surgical Data Re-Insertion into Staging Database
-- Method: Cross-database data restoration without wiping subsequent transactions.
-- -----------------------------------------------------------------------------
\connect grp_brewposdb_restore_test

\echo '\n--- [STEP 5] Performing Surgical Re-Insertion into grp_brewposdb_restore_test ---'
INSERT INTO public.menu_item (item_id, category_id, item_name, price, is_active)
VALUES (1, 1, 'Pumpkin Spice Latte', 140.00, FALSE);

-- -----------------------------------------------------------------------------
-- STEP 6: Post-Recovery Integrity & Parity Audit
-- -----------------------------------------------------------------------------
\echo '\n--- [STEP 6] Post-Recovery Verification ---'
SELECT item_id, category_id, item_name, price, is_active
FROM public.menu_item
WHERE item_id = 1;

SELECT COUNT(*) AS total_menu_items_restored FROM public.menu_item;

