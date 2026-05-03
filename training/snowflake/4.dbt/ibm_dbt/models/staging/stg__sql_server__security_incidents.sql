WITH source AS (
    SELECT * FROM {{ source('sql_server', 'security_incidents') }}
)

SELECT
    incident_id,
    org_id,
    incident_type,
    TRY_CAST(discovered_date AS DATE) AS discovered_date,
    severity
FROM source
