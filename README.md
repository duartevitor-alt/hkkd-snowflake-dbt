# Snowflake & dbt Training

Welcome! This training is a hands-on introduction to building a modern data platform on Snowflake.

You will start from zero — creating a Snowflake account, setting up access control, loading raw data, and finally transforming it into analytics-ready models using dbt. Each module builds on the previous one, so by the end you will have a working end-to-end pipeline running entirely on Snowflake.

---

## What You Will Learn

### Snowflake Core Concepts

The first part of the training focuses on Snowflake fundamentals:

- **RBAC (Role-Based Access Control)** — how Snowflake manages who can do what. You will implement a layered role model with ownership roles, access roles, and functional roles, and see firsthand how privilege boundaries are enforced across databases and schemas.

- **Data Ingestion** — how raw data lands in Snowflake. You will load CSV files into an internal stage and copy them into raw tables, learning the staging pattern that underpins most real-world Snowflake pipelines.

### dbt as the Transformation Layer

The second part introduces **dbt (data build tool)** as the engine that shapes and models the data in the transformed database.

Rather than writing ad-hoc SQL, dbt lets you define your transformations as versioned, testable SQL models organised into layers — from staging (cleaning raw data) through core dimensions and facts, up to business-facing marts. You will build the full model graph over the ingested dataset and run it against Snowflake using a dedicated service account.

---

## Modules

| # | Module | What you build |
|---|--------|----------------|
| 0 | Pre-requisites | Snowflake trial account + Python environment |
| 1 | Configuration | `config.toml` with named connections per role |
| 2 | RBAC | Roles, warehouses, databases, users, and grants |
| 3 | Ingestion | Schema, internal stage, raw tables, `COPY INTO` |
| 4 | dbt | Staging, core, and mart models on `TRANSFORMED_DEV` |
| 5 | dbt on Snowflake | Deploy and run dbt natively inside Snowflake |

Start with **Module 0 — Pre-requisites** in `training/snowflake/0.pre-requisites/`.
