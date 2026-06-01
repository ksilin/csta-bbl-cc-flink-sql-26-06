---
prompt: "Write a Flink SQL tumbling window query that counts vehicle telemetry signals per hour, grouped by vehicle_id. The table is called telemetry and has columns vehicle_id, signal_value, and recorded_at. Target runtime is Confluent Cloud."
model: claude-haiku-4-5
arm: with-skill
date: 2026-05-30
---

# Prompt 01: TVF Window Syntax

**Prompt:** Write a Flink SQL tumbling window query that counts vehicle telemetry signals per hour, grouped by vehicle_id. The table is called telemetry and has columns vehicle_id, signal_value, and recorded_at. Target runtime is Confluent Cloud.

**Model:** claude-haiku-4-5
**Arm:** with-skill (SKILL.md + reference files)
**Captured:** 2026-05-30

## Key Pattern

Uses CC-required TVF syntax (`TABLE(TUMBLE(...))`) instead of the deprecated `GROUP BY TUMBLE(...)` form.

## Response

```sql
SELECT
  window_start,
  window_end,
  vehicle_id,
  COUNT(*) as signal_count
FROM TABLE(
  TUMBLE(TABLE telemetry, DESCRIPTOR(recorded_at), INTERVAL '1' HOUR)
)
GROUP BY window_start, window_end, vehicle_id;
```

Correctly uses TVF syntax as required by CC (trap #18). Recommends running `EXPLAIN` before `CREATE ... AS SELECT` to validate the plan.
