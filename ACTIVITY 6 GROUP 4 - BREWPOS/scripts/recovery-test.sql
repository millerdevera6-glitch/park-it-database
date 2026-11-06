-- BrewPOS Activity 6: Controlled Recovery Simulation
-- IMPORTANT:
-- The simulation was already performed.
-- The original database and backup archive were not modified.
-- Only grp_brewposdb_restore_test was used for simulated data loss.

-- STEP 1: Connect to grp_brewposdb_restore_test before testing.

-- Record selected before simulated loss:
-- order_id = 1
-- item_id = 5
-- quantity = 2
-- sold_price = 90.00

-- STEP 2: Actual deletion command used during the simulation.
-- This command is intentionally commented out to prevent accidental execution.
-- DELETE FROM public.order_line_item
-- WHERE order_id = 1 AND item_id = 5
-- RETURNING order_id, item_id, quantity, sold_price;

-- STEP 3: Verify simulated loss in grp_brewposdb_restore_test.
-- Expected result: 0 rows.
SELECT *
FROM public.order_line_item
WHERE order_id = 1 AND item_id = 5;

-- STEP 4: Connect to grp_brewposdb_recovery_test.

-- Verify recovered record.
-- Expected: order_id 1, item_id 5, quantity 2, sold_price 90.00.
SELECT order_id, item_id, quantity, sold_price
FROM public.order_line_item
WHERE order_id = 1 AND item_id = 5;

-- STEP 5: Verify total recovered order-line records.
-- Expected result: 9.
SELECT COUNT(*) AS recovered_order_lines
FROM public.order_line_item;