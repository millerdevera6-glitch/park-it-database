-- ============================================================================
-- ACTIVITY 5: Query Performance Analysis
-- ============================================================================

-- Evaluation of the core Daily Sales report query using EXPLAIN ANALYZE
EXPLAIN (ANALYZE, BUFFERS)
SELECT COALESCE(SUM(l.quantity * l.sold_price), 0) AS total_sales,
       COUNT(DISTINCT t.order_id)                  AS order_count
FROM public.order_ticket t
JOIN public.order_line_item l ON l.order_id = t.order_id
WHERE t.order_timestamp >= CURRENT_DATE
  AND t.order_timestamp <  CURRENT_DATE + 1;
  