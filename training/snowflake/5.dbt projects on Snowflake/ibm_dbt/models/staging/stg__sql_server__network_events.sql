WITH source AS (
    SELECT * FROM {{ source('sql_server', 'network_events') }}
)

SELECT
    event_id,
    system_id,
    event_type,
    -- rename: TIMESTAMP is a reserved word in Snowflake
    TRY_CAST("TIMESTAMP" AS DATE) AS event_timestamp,
    severity
FROM source
