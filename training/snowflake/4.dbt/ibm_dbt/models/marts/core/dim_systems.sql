WITH stg AS (
    SELECT * FROM {{ ref('stg__sql_server__systems') }}
)

SELECT
    MD5(COALESCE(system_id, ''))  AS system_key,
    system_id,
    org_id,
    MD5(COALESCE(org_id, ''))     AS org_key,
    os_type,
    criticality
FROM stg
