#!/usr/bin/env bash
# Setup: create bbl-orders source table and produce initial data
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DEMO_DIR/../../scripts/lib.sh"

echo "=== Setup: bbl-orders ==="

# Create source table
echo "[setup] Creating source table..."
run_sql "talk-setup" "$DEMO_DIR/sql/setup.sql" --wait
delete_statement "talk-setup"

# Produce initial records (3 customers, 2 orders each)
echo "[setup] Producing initial records..."
confluent kafka topic produce bbl-orders \
  --cluster "$KAFKA_CLUSTER_ID" \
  --environment "$CONFLUENT_ENV_ID" \
  "${KAFKA_FLAGS[@]}" \
  --value-format jsonschema \
  "${SR_FLAGS[@]}" << 'JSONL'
{"order_id":"o-001","amount":29.99,"customer_id":"c-alice","order_time":"2026-05-18 10:00:00"}
{"order_id":"o-002","amount":14.50,"customer_id":"c-bob","order_time":"2026-05-18 10:00:10"}
{"order_id":"o-003","amount":89.00,"customer_id":"c-alice","order_time":"2026-05-18 10:00:20"}
{"order_id":"o-004","amount":5.00,"customer_id":"c-carol","order_time":"2026-05-18 10:00:30"}
{"order_id":"o-005","amount":42.50,"customer_id":"c-bob","order_time":"2026-05-18 10:00:40"}
{"order_id":"o-006","amount":15.00,"customer_id":"c-alice","order_time":"2026-05-18 10:00:50"}
JSONL

echo "[setup] Done. 6 records produced (3 customers)."
echo ""
echo "Next steps:"
echo "  - Open CC Console → Topics → bbl-orders → Messages"
echo "  - Open CC Console → Flink workspace"
echo "  - Run queries from the talking track"
echo "  - Use 'make flood COUNT=1000 KEYS=3' to produce more data"
