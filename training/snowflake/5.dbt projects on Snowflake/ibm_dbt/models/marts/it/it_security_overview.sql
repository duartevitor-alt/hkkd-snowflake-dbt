{{
    config(
        description="One-big-table for the IT Security team. One row per incident, enriched with organisation and affected system details."
    )
}}

WITH incidents AS (
    SELECT * FROM {{ ref('fct_security_incidents') }}
),

orgs AS (
    SELECT * FROM {{ ref('dim_organizations') }}
),

incident_systems AS (
    SELECT * FROM {{ ref('stg__sql_server__incident_systems') }}
),

systems AS (
    SELECT * FROM {{ ref('dim_systems') }}
),

-- Roll system details up to incident level
incident_system_details AS (
    SELECT
        ins.incident_id,
        COUNT(DISTINCT s.system_id)                                         AS system_count,
        LISTAGG(DISTINCT s.system_id, ', ') WITHIN GROUP (ORDER BY s.system_id)  AS affected_system_ids,
        LISTAGG(DISTINCT s.os_type,   ', ') WITHIN GROUP (ORDER BY s.os_type)    AS affected_os_types,
        MAX(CASE WHEN s.criticality = 'High'   THEN 1 ELSE 0 END)          AS has_high_criticality_system,
        MAX(CASE WHEN s.criticality = 'Medium' THEN 1 ELSE 0 END)          AS has_medium_criticality_system
    FROM incident_systems        AS ins
    LEFT JOIN systems            AS s ON ins.system_id = s.system_id
    GROUP BY ins.incident_id
)

SELECT
    -- Incident
    i.incident_key,
    i.incident_id,
    i.incident_type,
    i.discovered_date,
    i.severity                                                              AS incident_severity,
    i.affected_system_count,

    -- Organisation
    o.org_id,
    o.industry                                                              AS org_industry,
    o.country                                                               AS org_country,

    -- Affected systems (aggregated)
    isd.affected_system_ids,
    isd.affected_os_types,
    isd.has_high_criticality_system,
    isd.has_medium_criticality_system,

    -- Derived priority flag — useful for dashboard filtering
    CASE
        WHEN i.severity IN ('Critical', 'High')
             OR isd.has_high_criticality_system = 1
        THEN TRUE
        ELSE FALSE
    END                                                                     AS is_high_priority

FROM incidents                    AS i
LEFT JOIN orgs                    AS o   ON i.org_id      = o.org_id
LEFT JOIN incident_system_details AS isd ON i.incident_id = isd.incident_id
