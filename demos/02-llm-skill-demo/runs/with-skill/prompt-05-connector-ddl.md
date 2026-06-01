---
prompt: "Write a CREATE TABLE statement for a Kafka source in Confluent Cloud Flink SQL with topic 'vehicle-signals' and bootstrap servers."
model: claude-haiku-4-5
arm: with-skill
date: 2026-05-30
---

# Prompt 05: Connector DDL (No Kafka Connector)

**Prompt:** Write a CREATE TABLE statement for a Kafka source in Confluent Cloud Flink SQL with topic 'vehicle-signals' and bootstrap servers.

**Model:** claude-haiku-4-5
**Arm:** with-skill (SKILL.md + reference files)
**Captured:** 2026-05-30

## Key Pattern

Omits `'connector' = 'kafka'` and bootstrap servers -- CC auto-maps topic from table name and handles connectivity.

## Response

```sql
CREATE TABLE vehicle_signals (
  vehicle_id STRING,
  speed_kmh DOUBLE,
  fuel_level INT,
  recorded_at TIMESTAMP(3),
  WATERMARK FOR recorded_at AS recorded_at - INTERVAL '5' SECOND
) WITH (
  'value.format' = 'json-registry'
);
```

Topic auto-maps from table name. No `'connector' = 'kafka'` on CC (trap #3). Bootstrap servers are set at statement creation via CLI, not in DDL.
