---
prompt: "Write the CREATE TABLE DDL for a Flink SQL sink table on Confluent Cloud that outputs JSON to a Kafka topic. The table has columns order_id STRING and total DECIMAL(10,2)."
model: claude-haiku-4-5
arm: with-skill
date: 2026-05-30
---

# Prompt 02: JSON Format DDL

**Prompt:** Write the CREATE TABLE DDL for a Flink SQL sink table on Confluent Cloud that outputs JSON to a Kafka topic. The table has columns order_id STRING and total DECIMAL(10,2).

**Model:** claude-haiku-4-5
**Arm:** with-skill (SKILL.md + reference files)
**Captured:** 2026-05-30

## Key Pattern

Uses `'json-registry'` format (CC-only) instead of plain `'json'`, which fails on Confluent Cloud.

## Response

```sql
CREATE TABLE orders_output (
  order_id STRING,
  total DECIMAL(10, 2)
) WITH (
  'value.format' = 'json-registry',
  'changelog.mode' = 'append'
);
```

Uses `json-registry` as required by CC -- plain `'json'` is not supported (trap #20). No `'connector'` property needed.
