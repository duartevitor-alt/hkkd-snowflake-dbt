# Python Environment Setup

This project uses **[uv](https://github.com/astral-sh/uv)** — a fast Python package and project manager. It handles Python version management, virtual environment creation, and dependency installation in a single tool.

The project requires **Python 3.13+** and installs three main dependencies:

| Package | Purpose |
|---------|---------|
| `snowflake-cli` | The `snow` command-line tool for interacting with Snowflake |
| `dbt-snowflake` | dbt Core with the Snowflake adapter |
| `snowflake-snowpark-python[modin]` | Snowpark Python SDK + pandas-compatible API |

---

## Route A — uv (recommended)

### 1. Install uv

**macOS / Linux**
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**Windows (PowerShell)**
```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Restart your terminal after installation, then verify:

```bash
uv --version
```

---

### 2. Sync the project

From the **project root** (where `pyproject.toml` lives):

```bash
uv sync
```

This will:
1. Download and install Python 3.13 if not already present
2. Create a `.venv` virtual environment in the project root
3. Install all dependencies pinned in `uv.lock`

> `uv sync` uses the lock file (`uv.lock`) to guarantee every trainee installs the exact same package versions. You do not need to run `pip install` or activate the environment manually.

---

### 3. Verify the installation

```bash
# Snowflake CLI
uv run snow --version

# dbt
uv run dbt --version

# Python
uv run python --version
```

All commands should return a version number without errors.

---

### Running commands

Prefix any command with `uv run` to execute it inside the project's virtual environment without activating it:

```bash
uv run snow connection test -c local
uv run python source_app/ingestion/ingest_raw.py
uv run dbt run
```

Or activate the environment once for a session:

```bash
# macOS / Linux
source .venv/bin/activate

# Windows
.venv\Scripts\activate

# Then run commands directly
snow connection test -c local
```

---

## Route B — pip (alternative)

Use this route if you prefer to manage the environment yourself or cannot install uv.

### 1. Check your Python version

```bash
python --version   # must be 3.13 or higher
```

If you need to install Python 3.13, download it from [python.org/downloads](https://www.python.org/downloads/).

---

### 2. Create a virtual environment

```bash
python -m venv .venv
```

Activate it:

```bash
# macOS / Linux
source .venv/bin/activate

# Windows
.venv\Scripts\activate
```

---

### 3. Install dependencies

```bash
pip install \
  "snowflake-cli>=3.14" \
  "dbt-snowflake>=1.10.5" \
  "snowflake-snowpark-python[modin]>=1.41.0"
```

> Unlike `uv sync`, this installs the latest versions matching the constraints rather than the exact locked versions. This may occasionally cause version differences between trainees. If you hit unexpected errors, compare package versions with `pip list`.

---

### 4. Verify the installation

```bash
snow --version
dbt --version
python --version
```

---

## Troubleshooting

**`snow: command not found` after `uv sync`**
Use `uv run snow` instead, or activate the virtual environment first with `source .venv/bin/activate`.

**`uv sync` fails with a Python version error**
uv will attempt to download Python 3.13 automatically. If this is blocked by a corporate proxy, install Python 3.13 manually from [python.org](https://www.python.org/downloads/) and re-run `uv sync`.

**`ModuleNotFoundError` when running Python scripts**
Make sure you are running scripts with `uv run python ...` or that the virtual environment is activated.
