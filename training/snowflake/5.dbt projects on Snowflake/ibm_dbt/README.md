# ibm_dbt — Hands-on dbt Lab

In this lab you will build a dbt project end-to-end — from raw source tables to a mart ready for the IT Security team. One staging model is provided as a reference. You will create the remaining **13 models** yourself.

---

## Data Flow

```
 RAW_DEV.SQL_SERVER        TRANSFORMED_DEV
 (read-only source)
 ┌────────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────┐
 │   7 tables     │───►│   STAGING    │───►│     CORE     │───►│    IT    │
 │                │    │   7 models   │    │   6 models   │    │ 1 model  │
 │ organizations  │    │   (views)    │    │   (tables)   │    │ (table)  │
 │ users          │    └──────────────┘    └──────────────┘    └──────────┘
 │ systems        │
 │ login_logs     │
 │ network_events │
 │ security_      │
 │   incidents    │
 │ incident_      │
 │   systems      │
 └────────────────┘
```

---

## Layer Descriptions

### Source — `RAW_DEV.SQL_SERVER`

Raw tables loaded by the ingestion pipeline. All columns are `VARCHAR` — no typing or transformations have been applied. Treated as **read-only** in dbt; only the staging layer may reference sources directly.

Freshness is monitored via `METADATA$ROW_LAST_COMMIT_TIME` — a Snowflake system column populated automatically on each `COPY INTO`. Run `dbt source freshness` to check.

---

### Staging — `TRANSFORMED_DEV.staging` (views)

One model per source table. The **only** layer allowed to call `{{ source(...) }}`.

Responsibilities:
- Cast columns to correct data types (`TRY_CAST`)
- Rename columns that clash with SQL reserved words
- No business logic — keep it mechanical

Naming convention: `stg__<source>__<table>`

| Model | What to do |
|-------|-----------|
| `stg__sql_server__login_logs` | **provided** — use as reference |
| `stg__sql_server__organizations` | no renames needed |
| `stg__sql_server__users` | rename `role` → `user_role` (reserved word) |
| `stg__sql_server__systems` | no renames needed |
| `stg__sql_server__network_events` | rename `TIMESTAMP` → `event_timestamp`; cast to `DATE` |
| `stg__sql_server__security_incidents` | cast `discovered_date` to `DATE` |
| `stg__sql_server__incident_systems` | no renames needed |

---

### Core — `TRANSFORMED_DEV.core` (tables)

Dimensional models built on top of staging. Only `{{ ref(...) }}` calls — no sources.

Introduces two conventions used throughout this layer:

**Surrogate keys** — generated with `MD5(COALESCE(<natural_key>, ''))`. `COALESCE` is required because `MD5(NULL)` returns `NULL` in Snowflake, which would silently break any join on the key.

**Materialized as tables** — core models are queried frequently and should not re-read the source on every downstream query.

#### Dimensions — one row per entity

| Model | Columns |
|-------|---------|
| `dim_organizations` | `org_key`, `org_id`, `industry`, `country` |
| `dim_users` | `user_key`, `user_id`, `org_id`, `org_key`, `user_role` |
| `dim_systems` | `system_key`, `system_id`, `org_id`, `org_key`, `os_type`, `criticality` |

#### Facts — one row per event or transaction

| Model | Columns |
|-------|---------|
| `fct_login_events` | `login_key`, `login_id`, `user_key`, `login_time`, `ip_address`, `status`, `is_failed` |
| `fct_network_events` | `event_key`, `event_id`, `system_key`, `event_type`, `event_timestamp`, `severity` |
| `fct_security_incidents` | `incident_key`, `incident_id`, `org_key`, `incident_type`, `discovered_date`, `severity`, `affected_system_count` |

> Full column documentation and data tests are in `models/marts/core/core.yml`.

---

### IT Mart — `TRANSFORMED_DEV.it` (tables)

Denormalised models built for a specific business consumer. No joins needed downstream.

| Model | Description |
|-------|-------------|
| `it_security_overview` | One-big-table for the IT Security team. One row per incident, enriched with organisation details and aggregated system information. Includes a derived `is_high_priority` flag. |

> Full column documentation is in `models/marts/it/it.yml`.

---

## Lab — Build the 13 Models

You have one example to learn from (`stg__sql_server__login_logs`). Build the rest in order.

### Step 1 — Complete the staging layer (6 models)

For each empty file in `models/staging/`:

1. Open the provided `stg__sql_server__login_logs.sql` as a reference
2. Replace the source table name in `{{ source('sql_server', '<table>') }}`
3. Write an explicit `SELECT` — no `SELECT *`
4. Apply type casts and renames as described in the table above

```bash
dbt run  --select staging
dbt test --select staging
```

---

### Step 2 — Build the core dimensions (3 models)

For each dim model in `models/marts/core/`:

1. Reference the matching staging model with `{{ ref('stg__sql_server__...') }}`
2. Generate a surrogate key: `MD5(COALESCE(<id_column>, '')) AS <entity>_key`
3. Select all remaining columns from the staging model

```bash
dbt run  --select dim_organizations dim_users dim_systems
dbt test --select dim_organizations dim_users dim_systems
```

---

### Step 3 — Build the core facts (3 models)

`fct_login_events` and `fct_network_events` follow the same pattern as the dims.

`fct_security_incidents` is slightly more complex — it needs a pre-aggregated count of affected systems:

1. Use a CTE to count `incident_id` occurrences in `stg__sql_server__incident_systems`
2. `LEFT JOIN` that count back onto the incidents
3. Wrap with `COALESCE(..., 0)` so incidents with no systems return 0 rather than NULL

```bash
dbt run  --select fct_login_events fct_network_events fct_security_incidents
dbt test --select fct_login_events fct_network_events fct_security_incidents
```

---

### Step 4 — Build the IT mart (1 model)

`it_security_overview` joins everything together into a single wide table:

1. Start from `fct_security_incidents`
2. Join `dim_organizations` on `org_id`
3. Join `stg__sql_server__incident_systems` → `dim_systems`, roll system details up per incident using `LISTAGG`
4. Add the `is_high_priority` flag: `TRUE` when `severity IN ('Critical', 'High')` OR any affected system has `criticality = 'High'`

```bash
dbt run  --select it_security_overview
dbt test --select it_security_overview
```

---

### Run everything at once

```bash
dbt run
dbt test
```

---

## Useful Commands

```bash
dbt run --select +<model>      # model + all upstream dependencies
dbt test --select <model>      # tests for a single model
dbt source freshness           # check how fresh the source tables are
dbt docs generate && dbt docs serve   # browse the full lineage graph
```
