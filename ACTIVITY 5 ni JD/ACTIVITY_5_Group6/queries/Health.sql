SELECT
    current_database() AS database_name,
    version() AS server_version,
    pg_size_pretty(
        pg_database_size(current_database())
    ) AS database_size;

SELECT COUNT(*) AS total_tables
FROM information_schema.tables
WHERE table_schema = 'habalgo'
  AND table_type = 'BASE TABLE';

SELECT COUNT(*) AS total_sequences
FROM information_schema.sequences
WHERE sequence_schema = 'habalgo';