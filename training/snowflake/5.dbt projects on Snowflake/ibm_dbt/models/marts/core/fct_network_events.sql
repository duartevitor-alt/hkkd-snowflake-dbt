WITH stg AS (
    SELECT * FROM {{ ref('stg__sql_server__network_events') }}
)

SELECT
    MD5(COALESCE(event_id, ''))   AS event_key,
    event_id,
    system_id,
    MD5(COALESCE(system_id, ''))  AS system_key,
    event_type,
    event_timestamp,
    severity
FROM stg
