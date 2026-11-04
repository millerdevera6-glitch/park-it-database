# Query Performance Analysis – Group 7 CampusSafe

## Selected Query
The selected query retrieves submitted hazard reports and sorts them by submission date, newest first.

## Query Execution Plan
PostgreSQL used the following operations:
- Bitmap Index Scan using `idx_report_status`
- Bitmap Heap Scan on `hazard_report`
- Sort using quicksort

## EXPLAIN ANALYZE Results
- Estimated rows: 2
- Actual rows: 2
- Planning time: 0.380 ms
- Execution time: 1.005 ms
- Sort method: quicksort
- Sort memory: 25 kB

## Analysis
The query successfully used the existing status index to locate submitted reports. The estimated row count matched the actual result of two rows. PostgreSQL then retrieved the matching records and sorted them by submission date.

The execution time was approximately 1.005 milliseconds, indicating fast execution for the current small dataset.

## Recommendation
No additional index is recommended at this time. The existing status index already supports the filtering condition, and the query performs efficiently. Query performance should be monitored again as the number of hazard reports increases.