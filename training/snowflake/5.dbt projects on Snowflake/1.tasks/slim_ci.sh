#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(realpath "$SCRIPT_DIR/../ibm_dbt")"
CACHE_DIR="$PROJECT_DIR/cache"

echo "==> [1/4] Preparing slim CI artifacts on Snowflake..."
uv run snow sql \
    -q "CALL TRANSFORMED_DEV.PUBLIC.prepare_slim_ci();" \
    -c dbt

echo "==> [2/4] Downloading manifest.json from @my_dbt_stage/cache/..."
mkdir -p "$CACHE_DIR"
uv run snow stage copy \
    @TRANSFORMED_DEV.PUBLIC.my_dbt_stage/cache/target/ \
    "$CACHE_DIR/" \
    --recursive \
    -c dbt

echo "==> [3/4] Deploying dbt project to Snowflake..."
uv run snow dbt deploy ibm_dbt \
    --source "$PROJECT_DIR" \
    --force \
    -c dbt

echo "==> [4/4] Running slim CI — only modified models..."
uv run snow sql \
    -q "EXECUTE DBT PROJECT \"TRANSFORMED_DEV\".\"PUBLIC\".\"IBM_DBT\" ARGS='run --select state:modified+ --state cache/ --target dev';" \
    -c dbt

echo "==> Slim CI complete."
