# Snowflake RBAC & ELT Training

A hands-on training project covering Snowflake role-based access control, data ingestion with Snowpark, and transformations with dbt.

---

## Overview

This training walks through building a production-like data platform on Snowflake from scratch. By the end you will have:

- Applied a layered RBAC model with ownership, access, and functional roles
- Ingested raw CSV data into Snowflake using Snowpark pandas
- Explored how service account boundaries work in practice by switching snowcli connections
- Run dbt transformations over the ingested data

---

## Architecture

Two environments (DEV and PROD), each with two databases:

| Database | Purpose |
|----------|---------|
| `RAW_DEV` / `RAW_PROD` | Landing zone for raw ingested data. Schemas created by the ingest process. |
| `TRANSFORMED_DEV` / `TRANSFORMED_PROD` | dbt-managed. Schemas and models created by the dbt user. |

See the full role hierarchy in [`snowflake/rbac/rbac_diagram.md`](snowflake/rbac/rbac_diagram.md).

---

## RBAC Model

The model uses three layers of roles:

```
Ownership Roles     → own database objects (prevent orphaned objects)
    ↓
Schema Creator Roles → CREATE SCHEMA privilege only (scoped to one database)
    ↓
Access Roles        → READ / WRITE / CREATE on objects within schemas
    ↓
Functional Roles    → assigned to users; inherit the access roles they need
```

### Functional Roles (3 per environment)

| Role | Type | Access |
|------|------|--------|
| `ROLE_DATA_ENGINEER_{ENV}` | Human user | READ + WRITE on RAW and TRANSFORMED (DEV); READ-only on PROD |
| `ROLE_DATA_INGEST_{ENV}` | Service account | Full READ/WRITE/CREATE on RAW + schema creation |
| `ROLE_DBT_USER_{ENV}` | Service account | READ on RAW; full READ/WRITE/CREATE on TRANSFORMED + schema creation |

### Emulating Service Accounts Locally

Rather than deploying GitHub Actions, this training emulates service accounts by using different named connections in `config.toml`. Each connection authenticates as a different Snowflake user with a different default role, so switching connections is equivalent to switching identities.

```toml
[connections.data_engineer]
account   = "<your_account>"
user      = "<your_username>"
role      = "ROLE_DATA_ENGINEER_DEV"
warehouse = "WH_DATA_ENGINEER_DEV"

[connections.dbt_user]
account   = "<your_account>"
user      = "DBT_USER"
role      = "ROLE_DBT_USER_DEV"
warehouse = "WH_DBT_USER_DEV"

[connections.data_ingest]
account   = "<your_account>"
user      = "DATA_INGEST_USER"
role      = "ROLE_DATA_INGEST_DEV"
warehouse = "WH_DATA_INGEST_DEV"
```

---

## Prerequisites

- Python 3.11+
- [uv](https://github.com/astral-sh/uv) package manager
- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index) (`snow` command available)
- A Snowflake account with ACCOUNTADMIN access (a trial account works)

---

## Setup

**1. Clone the repo and install dependencies**

```bash
git clone <repo-url>
cd snowflake_dbt
uv sync
```

**2. Configure connections**

Copy the sample config and fill in your account details:

```bash
cp env.sample .env
```

Edit `config.toml` with your three connections (see template above).

**3. Bootstrap the Snowflake environment**

Run the RBAC script as ACCOUNTADMIN. This creates all roles, warehouses, databases, and users:

```bash
snow sql -f snowflake/rbac/rbac.sql -c <your_admin_connection>
```

**4. Set PAT credentials for service account users**

In Snowsight, generate Personal Access Tokens for `DBT_USER` and `DATA_INGEST_USER`, then add them to your `config.toml` connections:

```toml
[connections.dbt_user]
...
token = "<pat_token>"
authenticator = "oauth"

[connections.data_ingest]
...
token = "<pat_token>"
authenticator = "oauth"
```

---

## Labs

### Lab 1 — Explore the RBAC

Use snowcli to inspect what each role can see:

```bash
# List roles available to the data engineer
snow role list -c data_engineer

# List databases visible to the ingest user
snow object list database -c data_ingest

# Try accessing TRANSFORMED as ingest — should fail
snow sql -q "SELECT * FROM TRANSFORMED_DEV.INFORMATION_SCHEMA.TABLES" -c data_ingest
```

**Key question:** Why can `data_ingest` not query `TRANSFORMED_DEV`?

---

### Lab 2 — Ingest CSV Data

Run the ingestion script using the `data_ingest` identity:

```bash
cd source_app/ingestion
python ingest_raw.py
```

This reads all CSV files from `source_app/archive/` and loads them into `RAW_DEV.SOURCE1` as Snowflake tables using Snowpark pandas.

**Expected tables after ingestion:**
- `LOGIN_LOGS`, `SYSTEMS`, `USERS`, `NETWORK_EVENTS`, `ORGANIZATIONS`, `INCIDENT_SYSTEMS`, `SECURITY_INCIDENTS`

---

### Lab 3 — Query Raw Data as Data Engineer

```bash
snow sql -q "SELECT COUNT(*) FROM RAW_DEV.SOURCE1.USERS" -c data_engineer

# Try to create a table — should fail (no CREATE access)
snow sql -q "CREATE TABLE RAW_DEV.SOURCE1.TEST (id INT)" -c data_engineer
```

**Key question:** The data engineer has WRITE but not CREATE. What does that mean in practice?

---

### Lab 4 — Run dbt Transformations

```bash
# Activate the venv and run dbt as the dbt user
source .venv/bin/activate
dbt run --profiles-dir . --target dev
```

Verify that dbt created schemas and models in `TRANSFORMED_DEV`, then confirm the data engineer can read them:

```bash
snow sql -q "SELECT * FROM TRANSFORMED_DEV.<schema>.<model> LIMIT 10" -c data_engineer
```

---

## Project Structure

```
snowflake_dbt/
├── config.toml                   # Named snowcli connections
├── pyproject.toml                # Python dependencies (uv)
├── snowflake/
│   └── rbac/
│       ├── rbac.sql              # Full RBAC bootstrap script
│       └── rbac_diagram.md       # Visual role hierarchy (Mermaid)
└── source_app/
    ├── archive/                  # Source CSV files for ingestion
    │   ├── login_logs.csv
    │   ├── users.csv
    │   ├── organizations.csv
    │   ├── systems.csv
    │   ├── network_events.csv
    │   ├── security_incidents.csv
    │   └── incident_systems.csv
    └── ingestion/
        ├── connection.py         # Connection class (reads config.toml)
        └── ingest_raw.py         # CSV → Snowflake ingestion via Snowpark pandas
```

---

## Data Model

| Table | Key Columns | Description |
|-------|-------------|-------------|
| `USERS` | `user_id`, `org_id`, `role` | User registry |
| `ORGANIZATIONS` | `org_id`, `industry`, `country` | Organisation metadata |
| `SYSTEMS` | `system_id`, `org_id`, `os_type`, `criticality` | IT systems |
| `LOGIN_LOGS` | `login_id`, `user_id`, `login_time`, `ip_address`, `status` | Authentication events |
| `NETWORK_EVENTS` | `event_id`, `system_id`, `event_type`, `timestamp`, `severity` | Network activity |
| `SECURITY_INCIDENTS` | `incident_id`, `org_id`, `incident_type`, `discovered_date`, `severity` | Security incidents |
| `INCIDENT_SYSTEMS` | `incident_id`, `system_id` | Incident ↔ system mapping |
