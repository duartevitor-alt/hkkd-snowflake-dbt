WITH stg AS (
    SELECT * FROM {{ ref('stg__sql_server__organizations') }}
)

SELECT
    MD5(org_id)  AS org_key,
    org_id,
    industry,
    country
FROM stg
