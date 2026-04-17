WITH incidents AS (
    SELECT * FROM {{ ref('stg__sql_server__security_incidents') }}
),

affected_systems AS (
    SELECT
        incident_id,
        COUNT(*) AS affected_system_count
    FROM {{ ref('stg__sql_server__incident_systems') }}
    GROUP BY incident_id
)

SELECT
    MD5(i.incident_id)                        AS incident_key,
    i.incident_id,
    i.org_id,
    MD5(i.org_id)                             AS org_key,
    i.incident_type,
    i.discovered_date,
    i.severity,
    COALESCE(s.affected_system_count, 0)      AS affected_system_count
FROM incidents       AS i
LEFT JOIN affected_systems AS s ON i.incident_id = s.incident_id
