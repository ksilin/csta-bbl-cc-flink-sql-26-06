#!/usr/bin/env bash
# Teardown: drop all demo tables and clean up statements
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DEMO_DIR/../../scripts/lib.sh"

echo "=== Teardown: all demo tables ==="

# Delete any running statements
for prefix in talk-setup bbl-agg bbl-ctas; do
  delete_statement "$prefix" 2>/dev/null
done

# Drop tables via SQL
run_sql "talk-teardown" "$DEMO_DIR/sql/teardown.sql" --wait 2>/dev/null || true
delete_statement "talk-teardown"
run_sql "talk-ctas-teardown" "$DEMO_DIR/sql/ctas-teardown.sql" --wait 2>/dev/null || true
delete_statement "talk-ctas-teardown"

# Clean up topics that might linger
for topic in bbl-orders bbl-agg-append bbl-agg-upsert; do
  delete_topic "$topic"
done

echo "=== Teardown complete ==="
