---
prompt: "Write a Flink SQL tumbling window query that counts vehicle telemetry signals per hour, grouped by vehicle_id. The table is called telemetry and has columns vehicle_id, signal_value, and recorded_at. Target runtime is Confluent Cloud."
model: claude-haiku-4-5
arm: without-skill
date: 2026-05-30
---

# Prompt 01: Tumbling Window Query

**Prompt:** Write a Flink SQL tumbling window query that counts vehicle telemetry signals per hour, grouped by vehicle_id. The table is called telemetry and has columns vehicle_id, signal_value, and recorded_at. Target runtime is Confluent Cloud.

**Model:** claude-haiku-4-5
**Arm:** without-skill
**Captured:** 2026-05-30

## Trap

Uses deprecated OSS `GROUP BY TUMBLE()` syntax and `TUMBLE_START`/`TUMBLE_END` accessor functions instead of the CC-required TVF syntax (`TABLE(TUMBLE(...))`), and emits a CREATE TABLE with `'connector' = 'kafka'` and `'properties.bootstrap.servers'` which do not exist on CC.

## Response

```sql
SELECT 
  TUMBLE_START(recorded_at, INTERVAL '1' HOUR) AS window_start,
  TUMBLE_END(recorded_at, INTERVAL '1' HOUR) AS window_end,
  vehicle_id,
  COUNT(*) AS signal_count
FROM telemetry
GROUP BY 
  TUMBLE(recorded_at, INTERVAL '1' HOUR),
  vehicle_id;
```

Also includes a CREATE TABLE with OSS connector properties:

```sql
CREATE TABLE telemetry (
    vehicle_id STRING,
    signal_value DOUBLE,
    recorded_at TIMESTAMP(3),
    WATERMARK FOR recorded_at AS recorded_at - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'vehicle-telemetry',
    'properties.bootstrap.servers' = 'broker:9092',
    'format' = 'json'
);
```
