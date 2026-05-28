---
name: orchestracto
description: |
  Use Orchestracto and the ORC CLI to manage workflows, runs, and execution in the Nebius workflow orchestration platform built on YTsaurus.
  Use when the user asks about Orchestracto, needs to create/update/list workflows, create/get/restart runs, view logs, or debug workflow execution issues.
allowed-tools: Bash(orc *)
compatibility: Requires orchestracto-client (pip install orchestracto-client). The CLI must be installed and accessible as `orc`.
---

# Orchestracto and ORC CLI

Orchestracto is Nebius's workflow orchestration layer built on top of YTsaurus. It helps teams build repeatable, parameterized multi-step workflows with consistent authentication and execution semantics.

## Installation

```sh
pip install orchestracto-client
```

## Prerequisites

Before using the CLI, ensure environment variables are set:
- `YT_PROXY` — YTsaurus cluster proxy (e.g., `planck.yt.nebius.com`)
- `YT_TOKEN` — YTsaurus authentication token

**For Python SDK workflows** (`orc sdk process`): Docker must be running and logged in to the registry (e.g. `docker login tracto-registry.planck.yt.nebius.yt` or `cr.planck.yt.nebius.yt`). The processor builds per-step Docker images and pushes them. Typical build time is ~30–60s for a small multi-step workflow.

## Quick Reference

| Task | Command |
|------|---------|
| Update workflow from YAML | `orc workflow update --wf-path //path/to/workflow --from-file workflow.yaml` |
| Update workflow from Python SDK | `orc sdk process /local/path/workflow.py` (workflow path is read from the `@workflow` decorator) |
| Validate workflow | `orc workflow validate --wf-path //path/to/workflow` |
| Create a run | `orc run create --wf-path //path/to/workflow` |
| Create run with params | `orc run create --wf-path //path/to/workflow --wf-params '{"key": "value"}'` |
| Create run with labels | `orc run create --wf-path //path/to/workflow --label mylabel` |
| List runs | `orc workflow get-runs --wf-path //path/to/workflow` |
| Get run details | `orc run get --wf-path //path/to/workflow --run-id <run-id>` |
| Get run logs | `orc run get-logs --wf-path //path/to/workflow --run-id <run-id>` |
| Get logs for one step | `orc run get-logs --wf-path //path/to/workflow --run-id <run-id> --step-id <step_id>` |
| Restart failed steps | `orc run restart --wf-path //path/to/workflow --run-id <run-id>` |
| Restart all steps | `orc run restart --wf-path //path/to/workflow --run-id <run-id> --restart-all` |
| Restart specific step(s) | `orc run restart --wf-path //path/to/workflow --run-id <run-id> --restart-step step_id` |

**Note:** Do NOT use the standalone `orcsdk` command — it currently fails with an `ImportError` (`cannot import name 'main_cli' from 'orc_sdk.processor'`). Use `orc sdk process <file>` instead.

## Output Formats

Use `--format` to control output:
- `json` — JSON output (useful for parsing)
- `json_indent` — Pretty-printed JSON
- `yaml` — YAML output
- `tskv` — Tab-separated key-value

Example:
```sh
orc --format json workflow get-runs --wf-path //path/to/workflow | jq -r '.[] | .run_id'
```

## Workflow Commands

### Update/Create a Workflow

**From YAML/JSON (declarative):**
```sh
# From YAML file
orc workflow update --wf-path //path/to/workflow --from-file /local/workflow.yaml

# From JSON file
orc workflow update --wf-path //path/to/workflow --from-file /local/workflow.json --input-format json

# From stdin
cat workflow.yaml | orc workflow update --wf-path //path/to/workflow --from-stdin
```

**From Python SDK file (builds Docker images per step):**
```sh
orc sdk process /local/path/workflow.py
```

- The workflow path is read from the `@workflow(workflow_path=...)` decorator inside the file, NOT from a CLI flag.
- Each `@task` becomes a Docker image; deps from `.with_additional_requirements([...])` are pip-installed into the image.
- Re-running `orc sdk process` rebuilds only what changed (cached by `func_code_hash`).
- The processor logs include `Build N of K is done` lines and ends with `Workflow is updated`.

### Validate a Workflow

```sh
orc workflow validate --wf-path //path/to/workflow
```

### Get Runs for a Workflow

```sh
# Get all runs
orc workflow get-runs --wf-path //path/to/workflow

# Filter by labels
orc workflow get-runs --wf-path //path/to/workflow --label mylabel --label anotherlabel

# Filter by date range
orc --format json workflow get-runs --wf-path //path/to/workflow \
    --start-dt 2025-01-21T18:40:00Z --end-dt 2025-01-21T18:50:00Z
```

## Run Commands

### Create a Run

```sh
# Basic run
orc run create --wf-path //path/to/workflow
# Output: run_id: dc8f2600-972441b2-82331579-5654fcb1

# With label(s)
orc run create --wf-path //path/to/workflow --label mylabel

# With multiple labels
orc run create --wf-path //path/to/workflow --label mylabel --label anotherlbl

# With workflow parameters
orc run create --wf-path //path/to/workflow --wf-params '{"param1": "value1"}'

# From parameters file (YAML)
orc run create --wf-path //path/to/workflow --wf-params-file params.yaml
```

### Get Run Details

```sh
orc run get --wf-path //path/to/workflow --run-id <run-id>

# Get YT operation ID for the run
orc --format json run get --wf-path //path/to/workflow --run-id <run-id> | jq -r .yt_operation_id
```

### Get Run Logs

```sh
# All logs
orc run get-logs --wf-path //path/to/workflow --run-id <run-id>

# Logs for specific step
orc run get-logs --wf-path //path/to/workflow --run-id <run-id> --step-id step_id

# Last N lines
orc run get-logs --wf-path //path/to/workflow --run-id <run-id> | tail -n 50
```

### Stop a Run

```sh
orc run stop --wf-path //path/to/workflow --run-id <run-id>
```

### Restart a Run

```sh
# Restart failed steps only (default)
orc run restart --wf-path //path/to/workflow --run-id <run-id>

# Restart all steps including successful ones
orc run restart --wf-path //path/to/workflow --run-id <run-id> --restart-all

# Restart specific step(s) and their descendants
orc run restart --wf-path //path/to/workflow --run-id <run-id> --restart-step step_id_1 --restart-step step_id_2
```

## Workflow Definition (Python SDK)

Orchestracto workflows are defined using the Python SDK. Each `@task` runs in its own Docker container; the `@workflow` decorator wires them into a DAG.

### Minimal example

```python
import os
from orc_sdk import workflow, task

@task()
def my_step(input_param: str) -> str:
    print(f"Processing: {input_param}")
    return f"Result: {input_param}"

BASE_PATH = os.environ.get("WF_BASE_PATH", "//path/to/workflows")

@workflow(
    f"{BASE_PATH}/my_workflow",
    triggers=[],
)
def my_workflow(wfro, my_param: str = "default"):
    step1 = my_step(my_param).with_retries(3)
    wfro.register_first_step(step1)
```

Deploy with: `orc sdk process this_file.py`

### Full multi-step example

```python
from __future__ import annotations
import os, sys
from orc_sdk import workflow, task

# So `from mypkg.helpers import ...` works both locally and inside the container.
# Inside the container the file is at /orc/lib/<pkg>/<file>.py and PYTHONPATH=/orc/lib.
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

_WF_PATH = "//home/me/my_workflow"

# Inject a YT token (or any value from the YT secret store) as an env var inside each step.
_SECRET = dict(
    key="YT_TOKEN",
    value_src_type="secret_store",
    value_ref="//home/me/secrets:yt_token",   # //path:secret_name
)
_REQS = ["ytsaurus-client==0.13.47", "ytsaurus-yson==0.4.10"]

@task()
def step_a(run_date: str = "") -> None:
    import os, yt.wrapper as yt
    ytc = yt.YtClient(proxy="planck.yt.nebius.yt", token=os.environ["YT_TOKEN"])
    print("step A running", run_date, flush=True)

@task()
def step_b(run_date: str = "") -> None:
    print("step B running", run_date, flush=True)

@task()
def step_c(run_date: str = "") -> None:
    print("step C running", run_date, flush=True)

@workflow(
    workflow_path=_WF_PATH,
    triggers=[{"trigger_type": "cron", "params": {"cron_expression": "0 4 * * *"}}],
)
def the_workflow(wfro, run_date: str = ""):
    a = (step_a(run_date)
         .with_id("a")
         .with_secret(**_SECRET)
         .with_additional_requirements(_REQS)
         .with_memory_limit(1 * 1024 ** 3)
         .with_retries(2))
    b = (step_b(run_date)
         .with_id("b")
         .with_secret(**_SECRET)
         .with_additional_requirements(_REQS)
         .with_memory_limit(1 * 1024 ** 3)
         .with_retries(2))
    c = (step_c(run_date)
         .with_id("c")
         .with_secret(**_SECRET)
         .with_additional_requirements(_REQS)
         .with_memory_limit(4 * 1024 ** 3)
         .with_retries(1))

    wfro.register_first_step(a)
    a >> b >> c            # linear chain
    # a >> [b, c]          # fan-out
    # [b, c] >> d          # fan-in
```

### Step builder methods

Chain these onto the task call inside the workflow body:

| Method | Purpose |
|---|---|
| `.with_id("step_id")` | Stable step identifier — used in DAG inspection, logs, restarts. |
| `.with_retries(n)` | Number of retry attempts on failure. |
| `.with_additional_requirements([...])` | pip dependencies installed into this step's Docker image. |
| `.with_secret(key=..., value_src_type="secret_store", value_ref="//path:name")` | Inject an env var sourced from the YT secret store. |
| `.with_memory_limit(bytes)` | Container memory limit (use `4 * 1024 ** 3` for 4GB). |

### Triggers

```python
triggers=[]   # manual runs only (orc run create)

triggers=[{"trigger_type": "cron", "params": {"cron_expression": "0 4 * * *"}}]   # 04:00 UTC daily
```

Cron expressions are standard 5-field UTC. To pass workflow parameters from a cron trigger, configure them in the trigger params (advanced).

### Workflow params and orc run create

Workflow function parameters become run-time parameters:

```sh
orc run create --wf-path //home/me/my_workflow --wf-params '{"run_date": "2026-05-11"}'
```

`--wf-params` takes JSON. Only simple types (str, int, float, bool, JSON-encoded strings) are reliably supported. For list/dict params, pass a JSON-encoded **string** parameter and `json.loads()` it inside the task:

```python
preset_names_json: str = json.dumps(["a", "b", "c"])
# inside task: presets = json.loads(preset_names_json)
```

### Inspecting the deployed DAG

```sh
orc --format json run get --wf-path //path --run-id <id> \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('stage:', d['stage'])
for s in d['workflow']['steps']:
    print(f\"  {s['step_id']:12} depends_on={s.get('depends_on', [])}\")
"
```

## Finding Workflow Path

Workflow paths in YTsaurus typically follow patterns like:
- `//home/<user>/orchestracto/<workflow-name>`
- `//home/<team>/workflows/<workflow-name>`
- `//path/to/project/workflows/<name>`

## Examples

### Full Workflow Lifecycle

```sh
# 1. Update/create workflow
orc workflow update --wf-path //home/user/my-workflow --from-file workflow.yaml

# 2. Create a run
RUN_ID=$(orc run create --wf-path //home/user/my-workflow --label test-run | grep -o '[a-f0-9-]*$')
echo "Run ID: $RUN_ID"

# 3. Check status
orc run get --wf-path //home/user/my-workflow --run-id $RUN_ID

# 4. View logs
orc run get-logs --wf-path //home/user/my-workflow --run-id $RUN_ID | tail -n 20
```

### Query Specific Runs

```sh
# Find runs from last 24 hours with specific label
orc workflow get-runs --wf-path //path/to/workflow --label nightly

# Get run with YT operation ID
orc --format json run get --wf-path //path/to/workflow --run-id <id> | jq .yt_operation_id
```

## Troubleshooting

- **"YT_PROXY not set" error**: Ensure `YT_PROXY` and `YT_TOKEN` environment variables are set before running `orc`
- **"Workflow not found"**: Verify the workflow path exists in YTsaurus or create it first with `workflow update` (YAML) or `orc sdk process` (Python)
- **Run not starting**: Check if workflow has valid triggers or create a run explicitly with `orc run create`
- **Logs not showing**: Use `--step-id` to filter logs for specific steps
- **`orc sdk process` Docker errors**: Run `docker login <registry>` first (e.g. `docker login cr.planck.yt.nebius.yt`); make sure Docker daemon is running
- **`orcsdk` standalone fails with ImportError**: Known broken — use `orc sdk process <file>` instead
- **Import errors inside a task**: Ensure pip deps are listed in `.with_additional_requirements([...])`. The task container has only what you declare; nothing is inherited from the local environment.
- **`ModuleNotFoundError` for sibling packages inside a task**: Add `sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))` at the top of the workflow file. Inside the container the workflow file lives at `/orc/lib/<pkg>/<file>.py` and `PYTHONPATH=/orc/lib`, so this lets `from <pkg>.subpkg import ...` resolve.

## Additional Resources

- Documentation: `/Users/donotreply/nebo/nyt/docs/source/en/orchestracto/`
- Examples: https://github.com/tractoai/tracto-examples/tree/main/orchestracto
- Slack: [#yt-orchestracto](https://nebius.enterprise.slack.com/archives/C07PG0Q4Q2G)