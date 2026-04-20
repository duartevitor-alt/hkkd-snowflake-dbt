CREATE OR REPLACE PROCEDURE TRANSFORMED_DEV.PUBLIC.prepare_slim_ci()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    dbt_last_execution STRING;
    stage_last_run     STRING;
    copy_sql           STRING;
BEGIN
    -- 0. DEFINE CONTEXT
    USE SCHEMA TRANSFORMED_DEV.PUBLIC;

    -- 1. Get the query_id of the most recent IBM_DBT execution
    SELECT query_id
    INTO   :dbt_last_execution
    FROM   TABLE(TRANSFORMED_DEV.INFORMATION_SCHEMA.DBT_PROJECT_EXECUTION_HISTORY())
    WHERE  OBJECT_NAME = 'IBM_DBT'
    ORDER  BY query_end_time DESC
    LIMIT  1;

    -- 2. Locate the dbt artifacts produced by that execution
    SELECT SYSTEM$LOCATE_DBT_ARTIFACTS(:dbt_last_execution)
    INTO   :stage_last_run;

    -- 3. Create a dedicated stage to cache the artifacts (SSE encrypted, idempotent)
    CREATE STAGE IF NOT EXISTS my_dbt_stage
        ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

    -- 4. Copy the artifacts from the execution stage into the cache stage
    copy_sql := 'COPY FILES INTO @my_dbt_stage/cache/ FROM ' || :stage_last_run;
    EXECUTE IMMEDIATE :copy_sql;

    RETURN 'Artifacts copied from ' || :stage_last_run || ' to @my_dbt_stage/cache/';
END;
$$;
