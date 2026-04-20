WITH source AS (
    SELECT * FROM {{ source('sql_server', 'incident_systems') }}
)

SELECT
    incident_id,
    system_id
FROM source
