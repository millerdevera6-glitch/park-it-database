-- Check application account permissions

SELECT
    has_table_privilege(
        'lostandfound_app',
        'items',
        'SELECT'
    ) AS can_view_items,

    has_table_privilege(
        'lostandfound_app',
        'items',
        'INSERT'
    ) AS can_insert_items;


-- Check public account permissions

SELECT
    has_table_privilege(
        'lostandfound_public',
        'items',
        'SELECT'
    ) AS can_view_items,

    has_table_privilege(
        'lostandfound_public',
        'items',
        'UPDATE'
    ) AS can_update_items;