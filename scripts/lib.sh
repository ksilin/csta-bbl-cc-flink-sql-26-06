#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

[[ -f "$ROOT_DIR/.env" ]] && source "$ROOT_DIR/.env"

: "${CONFLUENT_ENV_ID:?Copy env.example → .env and set CONFLUENT_ENV_ID}"
: "${COMPUTE_POOL_ID:?Copy env.example → .env and set COMPUTE_POOL_ID}"
: "${KAFKA_CLUSTER_ID:?Copy env.example → .env and set KAFKA_CLUSTER_ID}"
: "${CLOUD_PROVIDER:?Set CLOUD_PROVIDER in .env (aws, gcp, or azure)}"
: "${CLOUD_REGION:?Set CLOUD_REGION in .env (e.g. eu-central-1)}"
: "${SR_ENDPOINT:?Set SR_ENDPOINT in .env (Schema Registry URL)}"
: "${SR_API_KEY:?Set SR_API_KEY in .env}"
: "${SR_API_SECRET:?Set SR_API_SECRET in .env}"
: "${KAFKA_API_KEY:?Set KAFKA_API_KEY in .env}"
: "${KAFKA_API_SECRET:?Set KAFKA_API_SECRET in .env}"

SR_FLAGS=(--schema-registry-endpoint "$SR_ENDPOINT" --schema-registry-api-key "$SR_API_KEY" --schema-registry-api-secret "$SR_API_SECRET")
KAFKA_FLAGS=(--api-key "$KAFKA_API_KEY" --api-secret "$KAFKA_API_SECRET")

run_sql() {
  local name="$1"
  local sql_file="$2"
  local wait_flag="${3:-}"

  local stmts=()
  local current=""
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*-- ]] && continue
    [[ -z "${line// /}" ]] && continue
    line="${line%%--*}"
    current+="$line "
    if [[ "$line" == *";" ]]; then
      current="${current%;*}"
      current="$(echo "$current" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
      [[ -n "$current" ]] && stmts+=("$current")
      current=""
    fi
  done < "$sql_file"
  [[ -n "${current// /}" ]] && stmts+=("$(echo "$current" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')")

  if (( ${#stmts[@]} == 1 )); then
    confluent flink statement create "$name" \
      --sql "${stmts[0]}" \
      --compute-pool "$COMPUTE_POOL_ID" \
      --database "$KAFKA_CLUSTER_ID" \
      --environment "$CONFLUENT_ENV_ID" \
      ${wait_flag}
  else
    local i=1
    for stmt in "${stmts[@]}"; do
      echo "  [run_sql] submitting ${name}-${i}/${#stmts[@]}..."
      confluent flink statement create "${name}-${i}" \
        --sql "$stmt" \
        --compute-pool "$COMPUTE_POOL_ID" \
        --database "$KAFKA_CLUSTER_ID" \
        --environment "$CONFLUENT_ENV_ID" \
        ${wait_flag}
      (( i++ ))
    done
  fi
}

delete_statement() {
  local name="$1"
  _try_delete_one() {
    if confluent flink statement describe "$1" \
         --cloud "$CLOUD_PROVIDER" --region "$CLOUD_REGION" &>/dev/null; then
      confluent flink statement delete "$1" \
        --cloud "$CLOUD_PROVIDER" --region "$CLOUD_REGION" --force
    fi
  }
  _try_delete_one "$name"
  for i in $(seq 1 10); do
    _try_delete_one "${name}-${i}" || true
  done
}

wait_for_statement() {
  local name="$1"
  local timeout="${2:-120}"
  local elapsed=0
  while (( elapsed < timeout )); do
    local stmt_status
    stmt_status=$(confluent flink statement describe "$name" \
      --cloud "$CLOUD_PROVIDER" --region "$CLOUD_REGION" \
      --output json 2>/dev/null | jq -r '.status // "UNKNOWN"')
    [[ "$stmt_status" == "RUNNING" || "$stmt_status" == "COMPLETED" ]] && return 0
    if [[ "$stmt_status" == "FAILED" ]]; then
      echo "Statement $name FAILED" >&2
      return 1
    fi
    sleep 5
    (( elapsed += 5 ))
  done
  echo "Timeout waiting for $name to reach RUNNING" >&2
  return 1
}

topic_exists() {
  local name="$1"
  confluent kafka topic list \
    --cluster "$KAFKA_CLUSTER_ID" \
    --environment "$CONFLUENT_ENV_ID" \
    --output json 2>/dev/null \
    | jq -e --arg n "$name" '.[] | select(.name == $n)' &>/dev/null
}

delete_topic() {
  local name="$1"
  if topic_exists "$name"; then
    confluent kafka topic delete "$name" \
      --cluster "$KAFKA_CLUSTER_ID" \
      --environment "$CONFLUENT_ENV_ID" --force 2>/dev/null || true
  fi
}

teardown_first() {
  local prefix="$1"
  local demo_dir="$2"
  local teardown="$demo_dir/sql/teardown.sql"
  if [[ -f "$teardown" ]]; then
    echo "[cleanup] Running teardown from prior run..."
    run_sql "${prefix}-pre-teardown" "$teardown" --wait 2>/dev/null || true
    delete_statement "${prefix}-pre-teardown"
    grep -oP '`\K[^`]+' "$teardown" | while read -r tname; do
      delete_topic "$tname"
    done
  fi
}
