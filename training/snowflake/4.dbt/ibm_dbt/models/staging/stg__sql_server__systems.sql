WITH source AS (
    SELECT * FROM {{ source('sql_server', 'systems') }}
)

SELECT
    system_id,
    org_id,
    os_type,
    criticality
FROM source
