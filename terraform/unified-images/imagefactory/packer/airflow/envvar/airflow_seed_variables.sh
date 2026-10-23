#!/bin/bash
set -euo pipefail

count=0

while IFS='=' read -r name _; do
  case "$name" in
    AIRFLOW_VAR_*) ;;
    *) continue ;;
  esac

  key="${name#AIRFLOW_VAR_}"
  [[ -z "$key" ]] && continue

  value="$(printenv "$name" || true)"
  /usr/local/bin/airflow variables set "$key" "$value"
  echo "Seeded Airflow variable: $key"
  count=$((count + 1))
done < <(env)

echo "Seeded $count Airflow variables from AIRFLOW_VAR_ envs"