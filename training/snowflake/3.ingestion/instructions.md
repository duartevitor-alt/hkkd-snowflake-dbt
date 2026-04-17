# Module 3: Data Ingestion

## What You Will Learn

- How to load CSV files into Snowflake using internal stages and `COPY INTO`
- What an internal stage is and why it exists
- How to use snowcli to upload files (`PUT`) and run SQL from the terminal
- How the `ingestion` connection maps to a specific role and warehouse (RBAC in action)

---

## Source Data

This module loads **7 CSV files** that represent a fictional security monitoring dataset. All files live in this folder alongside these instructions.

| File | Table | Description |
|------|-------|-------------|
| `organizations.csv` | `ORGANIZATIONS` | 120 organisations with industry and country |
| `users.csv` | `USERS` | 1,500 users, each belonging to an organisation |
| `systems.csv` | `SYSTEMS` | 600 IT systems with OS type and criticality rating |
| `login_logs.csv` | `LOGIN_LOGS` | 6,000 authentication events (success / failed) |
| `network_events.csv` | `NETWORK_EVENTS` | 5,000 network activity events with severity |
| `security_incidents.csv` | `SECURITY_INCIDENTS` | 500 security incidents per organisation |
| `incident_systems.csv` | `INCIDENT_SYSTEMS` | Junction table linking incidents to systems |

All data lands in the schema **`RAW_DEV.SQL_SERVER`** — representing a source system (SQL Server) ingested into the raw layer.

---

## Ingestion Architecture

Rather than loading files directly into tables, Snowflake uses a **staging** pattern:

```
Local CSV files
      │
      │  PUT (upload via snowcli)
      ▼
 Internal Stage  (RAW_DEV.SQL_SERVER.LANDING)
      │
      │  COPY INTO (Snowflake reads from stage)
      ▼
 Snowflake Tables  (RAW_DEV.SQL_SERVER.*)
```

**Why stages?**
- Files are validated and transformed *before* hitting tables
- Failed rows can be skipped or quarantined without aborting the whole load
- The stage acts as a reliable handoff point between the upload and the load — you can re-run `COPY INTO` without re-uploading

**Role in use:** All steps in the SQL route use the **`ingestion`** connection (`DATA_INGEST_USER` / `ROLE_DATA_INGEST_DEV`). This role has full read/write/create access on `RAW_DEV`, which is exactly what ingestion needs — and nothing more.

---

## Route A — SQL + snowcli (step by step)

Run each step from the **project root** using `uv run snow sql`.

---

### Step 1 — Create the schema

**File:** `3.2.create_schema.sql`

```bash
uv run snow sql -f "training/snowflake/3. ingestion/3.2.create_schema.sql" -c ingestion
```

This creates the `SQL_SERVER` schema inside `RAW_DEV` with managed access:

```sql
CREATE SCHEMA IF NOT EXISTS RAW_DEV.SQL_SERVER WITH MANAGED ACCESS;
```

> **Managed access** means only the schema owner (or ACCOUNTADMIN) can grant privileges on objects inside it. This prevents individual table owners from bypassing the RBAC model.

---

### Step 2 — Create the internal stage

**File:** `3.3.stages/landing.sql`

```bash
uv run snow sql -f "training/snowflake/3. ingestion/3.3.stages/landing.sql" -c ingestion
```

This creates an internal named stage called `LANDING` with directory mode enabled:

```sql
CREATE OR ALTER STAGE RAW_DEV.SQL_SERVER.LANDING
  DIRECTORY = (ENABLE = TRUE);
```

> An **internal stage** is Snowflake-managed storage. Files uploaded here are stored in Snowflake's own cloud bucket — no external S3 or Azure setup needed. Directory mode allows you to browse and query staged files like a filesystem.

---

### Step 3 — Upload the CSV files to the stage

**File:** `3.3.stages/scripts/put_files.sh`

```bash
bash "training/snowflake/3. ingestion/3.3.stages/scripts/put_files.sh"
```

This script loops through all `.csv` files and runs a `PUT` command for each one:

```sql
PUT file:///absolute/path/to/file.csv @RAW_DEV.SQL_SERVER.LANDING
  AUTO_COMPRESS=FALSE
  OVERWRITE=TRUE;
```

Expected output:
```
Uploading files from: .../training/snowflake/3. ingestion
Target stage: @RAW_DEV.SQL_SERVER.LANDING
---
Uploading incident_systems.csv ... done
Uploading login_logs.csv ... done
...
Done.
```

> **Verify in Snowsight:** Navigate to *Data → Databases → RAW_DEV → SQL_SERVER → Stages → LANDING* and confirm all 7 files are listed.

---

### Step 4 — Create the tables

**File:** `3.4.tables/create/create_all.sql`

```bash
uv run snow sql -f "training/snowflake/3. ingestion/3.4.tables/create/create_all.sql" -c ingestion
```

This runs all 7 `CREATE OR REPLACE TABLE` statements. Each table mirrors the columns of its CSV file, with all columns typed as `VARCHAR` — preserving the raw source values exactly as received, without any type casting or transformation.

> Raw layer best practice: keep data as-is. Type casting and business logic belong in the transformation layer (Module 4).

To inspect one of the DDL files individually:

```bash
uv run snow sql -f "training/snowflake/3. ingestion/3.4.tables/create/users.sql" -c ingestion
```

---

### Step 5 — Load the tables

**File:** `3.4.tables/load/load_all.sql`

```bash
uv run snow sql -f "training/snowflake/3. ingestion/3.4.tables/load/load_all.sql" -c ingestion
```

This runs a `COPY INTO` for each table, reading from the stage:

```sql
TRUNCATE TABLE IF EXISTS RAW_DEV.SQL_SERVER.USERS;

COPY INTO RAW_DEV.SQL_SERVER.USERS
FROM @RAW_DEV.SQL_SERVER.LANDING/users.csv
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
FILE_FORMAT = (
    TYPE = CSV
    PARSE_HEADER = TRUE
);
```

`MATCH_BY_COLUMN_NAME` maps CSV headers to table columns by name, so column order in the file doesn't matter. `PARSE_HEADER = TRUE` tells Snowflake to read the first row as column names rather than data.

---

### Step 6 — Verify

```bash
# Row counts for all tables
uv run snow sql -q "
  SELECT 'USERS'              AS tbl, COUNT(*) AS rows FROM RAW_DEV.SQL_SERVER.USERS              UNION ALL
  SELECT 'ORGANIZATIONS',               COUNT(*) FROM RAW_DEV.SQL_SERVER.ORGANIZATIONS             UNION ALL
  SELECT 'SYSTEMS',                     COUNT(*) FROM RAW_DEV.SQL_SERVER.SYSTEMS                   UNION ALL
  SELECT 'LOGIN_LOGS',                  COUNT(*) FROM RAW_DEV.SQL_SERVER.LOGIN_LOGS                UNION ALL
  SELECT 'NETWORK_EVENTS',              COUNT(*) FROM RAW_DEV.SQL_SERVER.NETWORK_EVENTS            UNION ALL
  SELECT 'SECURITY_INCIDENTS',          COUNT(*) FROM RAW_DEV.SQL_SERVER.SECURITY_INCIDENTS        UNION ALL
  SELECT 'INCIDENT_SYSTEMS',            COUNT(*) FROM RAW_DEV.SQL_SERVER.INCIDENT_SYSTEMS;
" -c ingestion
```

Expected results:

| Table | Rows |
|-------|------|
| USERS | 1,500 |
| ORGANIZATIONS | 120 |
| SYSTEMS | 600 |
| LOGIN_LOGS | 6,000 |
| NETWORK_EVENTS | 5,000 |
| SECURITY_INCIDENTS | 500 |
| INCIDENT_SYSTEMS | 500 |

---

## RBAC Checkpoint

Try running one of the load commands with a different connection:

```bash
# Should fail — data engineer has no CREATE privilege on RAW_DEV
uv run snow sql -f "training/snowflake/3. ingestion/3.4.tables/create/users.sql" -c local
```

This demonstrates that the RBAC model from Module 2 is actively enforced — only `ROLE_DATA_INGEST_DEV` has the privileges needed to create tables and load data into `RAW_DEV`.
