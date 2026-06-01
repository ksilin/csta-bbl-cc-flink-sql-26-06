#!/usr/bin/env bash
# produce-orders.sh - Generate and produce N order records to a Kafka topic.
#
# Generates records with configurable key cardinality (distinct customer IDs)
# and advancing timestamps. Useful for:
#   - State growth demos (high --keys → many distinct GROUP BY entries)
#   - Windowed aggregation demos (timestamps span multiple windows)
#
# Usage:
#   ./scripts/produce-orders.sh --topic bbl-orders --count 5000
#   ./scripts/produce-orders.sh --topic bbl-orders --count 5000 --keys 5000
#   make flood COUNT=5000
#
# Options:
#   --topic <name>   Kafka topic to produce to (required)
#   --count <N>      Number of records to produce (default: 1000)
#   --keys  <K>      Number of distinct customer IDs (default: same as count)
#   --dry-run        Print JSONL to stdout without producing
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

TOPIC=""
COUNT=1000
KEYS=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --topic)   TOPIC="$2"; shift 2 ;;
    --count)   COUNT="$2"; shift 2 ;;
    --keys)    KEYS="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$TOPIC" ]] && { echo "Error: --topic required" >&2; exit 1; }
KEYS="${KEYS:-$COUNT}"

generate_records() {
  local count="$1"
  local keys="$2"
  awk -v n="$count" -v k="$keys" 'BEGIN {
    srand(42)
    for (i = 1; i <= n; i++) {
      cid = ((i - 1) % k) + 1
      amount = int(rand() * 9900 + 100) / 100.0
      min = int((i - 1) / 60) % 60
      sec = (i - 1) % 60
      printf "{\"order_id\":\"o-%05d\",\"amount\":%.2f,\"customer_id\":\"c-%04d\",\"order_time\":\"2026-05-18 10:%02d:%02d\"}\n", \
        i, amount, cid, min, sec
    }
  }'
}

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[dry-run] Generating $COUNT records ($KEYS distinct keys)..."
  generate_records "$COUNT" "$KEYS" | head -n 5
  echo "... ($((COUNT - 5)) more)"
  exit 0
fi

echo "[produce] Generating $COUNT records ($KEYS distinct keys) → topic $TOPIC..."
generate_records "$COUNT" "$KEYS" | \
  confluent kafka topic produce "$TOPIC" \
    --cluster "$KAFKA_CLUSTER_ID" \
    --environment "$CONFLUENT_ENV_ID" \
    "${KAFKA_FLAGS[@]}" \
    --value-format jsonschema \
    "${SR_FLAGS[@]}"
echo "[produce] Done - $COUNT records sent."
