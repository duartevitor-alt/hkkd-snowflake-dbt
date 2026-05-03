WITH source AS (
    SELECT * FROM {{ source('sql_server', 'users') }}
)

SELECT
    user_id,
    org_id,
    -- rename: ROLE is a reserved word in Snowflake
    "ROLE" AS user_role
FROM source
