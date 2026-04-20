WITH stg AS (
    SELECT * FROM {{ ref('stg__sql_server__login_logs') }}
)

SELECT
    MD5(COALESCE(login_id, ''))  AS login_key,
    login_id,
    user_id,
    MD5(COALESCE(user_id, ''))   AS user_key,
    login_time,
    ip_address,
    status,
    CASE WHEN status = 'Failed' THEN 1 ELSE 0 END AS is_failed
FROM stg
