#!/bin/bash
set -euo pipefail

# Trigger `airflow dags reserialize` only when scheduler log contains
# "not found in serialized_dag table".

MARKER_DIR="/opt/airflow/.bootstrap"
MARKER_FILE="$MARKER_DIR/dag_reserialize.done"
LOCK_FILE="/opt/airflow/.bootstrap/dag_reserialize.lock"
VHOST="${AIRFLOW_VHOST:-c48}"
DAGS_DIR="/opt/airflow/${VHOST}_airflow"
AIRFLOW_BIN="/usr/local/bin/airflow"
SCHEDULER_LOG="/var/log/scheduler.log"
TRIGGER_PATTERN="not found in serialized_dag table"

mkdir -p "$MARKER_DIR"
echo "the using vhost is $VHOST, dags dir is $DAGS_DIR"

# Prevent duplicate bootstrap attempts when multiple services start closely.
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "[dag_reserialize] Another reserialize process is running, skip."
  exit 0
fi

if [[ -f "$MARKER_FILE" ]]; then
  echo "[dag_reserialize] Marker exists ($MARKER_FILE), skip reserialize."
  exit 0
fi

if [[ ! -d "$DAGS_DIR" ]]; then
  echo "[dag_reserialize] Dags directory not found ($DAGS_DIR), skip for now."
  exit 0
fi

if [[ ! -x "$AIRFLOW_BIN" ]]; then
  AIRFLOW_BIN="$(command -v airflow || true)"
fi

if [[ -z "$AIRFLOW_BIN" ]]; then
  echo "[dag_reserialize] airflow binary not found."
  exit 1
fi

if [[ ! -f "$SCHEDULER_LOG" ]]; then
  echo "[dag_reserialize] Scheduler log not found ($SCHEDULER_LOG), skip."
  exit 0
fi

if ! grep -q "$TRIGGER_PATTERN" "$SCHEDULER_LOG"; then
  echo "[dag_reserialize] Trigger keyword not found in scheduler log, skip." //
  exit 0
fi

echo "[dag_reserialize] Trigger keyword found. Running one-time reserialize..."
if "$AIRFLOW_BIN" dags reserialize; then
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "$MARKER_FILE"
  echo "[dag_reserialize] Reserialize completed successfully."
  exit 0
fi

echo "[dag_reserialize] Reserialize failed; marker not written. Will retry on next start."
exit 1