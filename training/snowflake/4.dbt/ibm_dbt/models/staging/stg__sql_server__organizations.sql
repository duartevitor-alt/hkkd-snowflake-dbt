WITH source AS (
    SELECT * FROM {{ source('sql_server', 'organizations') }}
)

SELECT
    org_id,
    industry,
    country
FROM source
