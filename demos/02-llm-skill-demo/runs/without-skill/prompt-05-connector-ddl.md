---
prompt: "Write a CREATE TABLE statement for a Kafka source in Confluent Cloud Flink SQL with topic 'vehicle-signals' and bootstrap servers."
model: claude-haiku-4-5
arm: without-skill
date: 2026-05-30
---

# Prompt 05: Connector DDL for CC

**Prompt:** Write a CREATE TABLE statement for a Kafka source in Confluent Cloud Flink SQL with topic 'vehicle-signals' and bootstrap servers.

**Model:** claude-haiku-4-5
**Arm:** without-skill
**Captured:** 2026-05-30

## Trap

Uses `'connector' = 'kafka'` with explicit `'properties.bootstrap.servers'`, SASL config, and `'format' = 'json'`. On CC, Kafka topics are auto-mapped as tables -- no connector property, no bootstrap servers, no auth config in DDL.

## Response

```sql
CREATE TABLE vehicle_signals (
    vehicle_id STRING,
    signal_type STRING,
    signal_value DOUBLE,
    timestamp_ms BIGINT,
    ts AS TO_TIMESTAMP(FROM_UNIXTIME(timestamp_ms)),
    WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'vehicle-signals',
    'properties.bootstrap.servers' = 'pkc-xxxxx.region.provider.confluent.cloud:9092',
    'properties.security.protocol' = 'SASL_SSL',
    'properties.sasl.jaas.config' = '...',
    'format' = 'json',
    'scan.startup.mode' = 'earliest-offset'
);
```
