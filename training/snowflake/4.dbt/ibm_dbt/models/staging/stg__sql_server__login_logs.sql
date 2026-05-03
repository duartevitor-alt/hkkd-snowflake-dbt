WITH source AS (
    SELECT * FROM {{ source('sql_server', 'login_logs') }}
)

SELECT
    login_id,
    user_id,
    TRY_CAST(login_time AS DATE) AS login_time,
    ip_address,
    status
FROM source
