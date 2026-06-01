#!/usr/bin/env bash
# run.sh - LLM Skill Demo: live side-by-side comparison
#
# Runs 6 prompts through Claude twice each:
#   1. Without skill (neutral system prompt)
#   2. With skill (SKILL.md + references injected)
#
# Audience sees both outputs live, then pattern-match scoring.
#
# Usage:
#   make demo-llm-run
#   CC_FLINK_EVAL_MODEL=claude-haiku-4-5 make demo-llm-run
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$HOME/.claude/skills/cc-flink-sql"
MODEL="${CC_FLINK_EVAL_MODEL:-claude-haiku-4-5}"

# Load skill context (SKILL.md + all reference files)
load_skill_context() {
  local ctx
  ctx="$(cat "$SKILL_DIR/SKILL.md")"
  for ref in "$SKILL_DIR/references/"*.md; do
    [[ -f "$ref" ]] && ctx="$ctx"$'\n\n'"--- $(basename "$ref") ---"$'\n\n'"$(cat "$ref")"
  done
  echo "$ctx"
}

SKILL_CONTEXT="$(load_skill_context)"
NEUTRAL_SYSTEM="You are a helpful assistant. Answer the user's question."
TMPDIR_DEMO="$(mktemp -d /tmp/cc-flink-llm-demo-XXXX)"

run_claude_arm() {
  local system_prompt="$1"
  local prompt="$2"
  echo "$prompt" | claude -p \
    --disable-slash-commands \
    --output-format text \
    --system-prompt "$system_prompt" \
    --model "$MODEL" \
    2>/dev/null
}

# --- Prompt definitions (6 most reproducible traps) ---
PROMPT_IDS=(
  "trap-tvf-window"
  "trap-json-format"
  "trap-proctime"
  "trap-datastream"
  "trap-connector-ddl"
  "trap-state-ttl"
)

declare -A PROMPTS
PROMPTS[trap-tvf-window]="Write a Flink SQL tumbling window query that counts vehicle telemetry signals per hour, grouped by vehicle_id. The table is called telemetry and has columns vehicle_id, signal_value, and recorded_at. Target runtime is Confluent Cloud."
PROMPTS[trap-json-format]="Write the CREATE TABLE DDL for a Flink SQL sink table on Confluent Cloud that outputs JSON to a Kafka topic. The table has columns order_id STRING and total DECIMAL(10,2)."
PROMPTS[trap-proctime]="On Confluent Cloud Flink SQL, I need to enrich streaming orders with customer data from an external Postgres database. Write the lookup join pattern."
PROMPTS[trap-datastream]="Write a Confluent Cloud Flink job in Java to filter Kafka messages by vehicle_id."
PROMPTS[trap-connector-ddl]="Write a CREATE TABLE statement for a Kafka source in Confluent Cloud Flink SQL with topic 'vehicle-signals' and bootstrap servers."
PROMPTS[trap-state-ttl]="How do I set state TTL for a Flink SQL statement on Confluent Cloud?"

declare -A TRAP_LABELS
TRAP_LABELS[trap-tvf-window]="OSS TUMBLE syntax vs CC TVF syntax"
TRAP_LABELS[trap-json-format]="'json' vs 'json-registry' format"
TRAP_LABELS[trap-proctime]="PROCTIME()/JDBC vs KEY_SEARCH_AGG"
TRAP_LABELS[trap-datastream]="Java DataStream API vs SQL-only"
TRAP_LABELS[trap-connector-ddl]="connector/bootstrap.servers vs auto-mapping"
TRAP_LABELS[trap-state-ttl]="table.exec.state.ttl vs sql.state-ttl"

echo "=== LLM Skill Demo: CC Flink SQL ==="
echo "Model: $MODEL"
echo "6 prompts × 2 arms = 12 LLM calls"
echo "Skill context: ${#SKILL_CONTEXT} chars"
echo ""

for pid in "${PROMPT_IDS[@]}"; do
  prompt="${PROMPTS[$pid]}"
  label="${TRAP_LABELS[$pid]}"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "[$pid] $label"
  echo ""
  echo "PROMPT: $prompt"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # --- Without skill ---
  echo "▼ WITHOUT SKILL ─────────────────────────────────────────────────────"
  no_skill_out="$(run_claude_arm "$NEUTRAL_SYSTEM" "$prompt")"
  echo "$no_skill_out"
  echo "$no_skill_out" > "$TMPDIR_DEMO/${pid}-no-skill.txt"
  echo "─────────────────────────────────────────────────────────────────────"
  echo ""

  # --- With skill ---
  echo "▼ WITH SKILL ────────────────────────────────────────────────────────"
  with_skill_out="$(run_claude_arm "$SKILL_CONTEXT" "$prompt")"
  echo "$with_skill_out"
  echo "$with_skill_out" > "$TMPDIR_DEMO/${pid}-with-skill.txt"
  echo "─────────────────────────────────────────────────────────────────────"
  echo ""
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Same prompts, same model ($MODEL). Only difference: system prompt."
echo ""
echo "Without skill → Claude defaults to OSS Flink / generic patterns"
echo "With skill    → Claude uses CC-specific syntax and avoids traps"
echo ""
echo "Full outputs saved to: $TMPDIR_DEMO/"
echo ""
echo "=== LLM Skill Demo Complete ==="
