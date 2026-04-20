WITH stg AS (
    SELECT * FROM {{ ref('stg__sql_server__users') }}
)

SELECT
    MD5(COALESCE(user_id, ''))  AS user_key,
    user_id,
    org_id,
    MD5(COALESCE(org_id, ''))   AS org_key,
    user_role
FROM stg
