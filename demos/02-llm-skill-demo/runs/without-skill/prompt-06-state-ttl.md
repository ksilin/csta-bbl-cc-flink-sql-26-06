---
prompt: "How do I set state TTL for a Flink SQL statement on Confluent Cloud?"
model: claude-haiku-4-5
arm: without-skill
date: 2026-05-30
---

# Prompt 06: State TTL Configuration

**Prompt:** How do I set state TTL for a Flink SQL statement on Confluent Cloud?

**Model:** claude-haiku-4-5
**Arm:** without-skill
**Captured:** 2026-05-30

## Trap

Uses OSS Flink syntax `SET 'table.exec.state.ttl'` which is not the correct property name on CC. Also suggests setting it in a CREATE TABLE WITH clause, which is not how state TTL works on CC either.

## Response

```sql
-- Session-level configuration
SET 'table.exec.state.ttl' = '10h';

-- Then run your stateful query
SELECT vehicle_id, COUNT(*) AS total_signals
FROM telemetry
GROUP BY vehicle_id;
```

Also suggests per-table TTL in the WITH clause:

```sql
CREATE TABLE aggregated_signals (
    vehicle_id STRING,
    total_signals BIGINT
) WITH (
    'connector' = 'kafka',
    'topic' = 'aggregated-signals',
    'table.exec.state.ttl' = '10h'
);
```
