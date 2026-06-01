---
prompt: "Write the CREATE TABLE DDL for a Flink SQL sink table on Confluent Cloud that outputs JSON to a Kafka topic. The table has columns order_id STRING and total DECIMAL(10,2)."
model: claude-haiku-4-5
arm: without-skill
date: 2026-05-30
---

# Prompt 02: JSON Format Sink DDL

**Prompt:** Write the CREATE TABLE DDL for a Flink SQL sink table on Confluent Cloud that outputs JSON to a Kafka topic. The table has columns order_id STRING and total DECIMAL(10,2).

**Model:** claude-haiku-4-5
**Arm:** without-skill
**Captured:** 2026-05-30

## Trap

Uses `'value.format' = 'json'` instead of CC-required `'value.format' = 'json-registry'`, and specifies `'connector' = 'kafka'` with explicit bootstrap servers and SASL properties that are not used on CC.

## Response

```sql
CREATE TABLE order_sink (
    order_id STRING,
    total DECIMAL(10, 2)
) WITH (
    'connector' = 'kafka',
    'topic' = 'orders',
    'properties.bootstrap.servers' = '<bootstrap-url>:9092',
    'properties.security.protocol' = 'SASL_SSL',
    'properties.sasl.mechanism' = 'PLAIN',
    'properties.sasl.jaas.config' = '...',
    'value.format' = 'json'
);
```
