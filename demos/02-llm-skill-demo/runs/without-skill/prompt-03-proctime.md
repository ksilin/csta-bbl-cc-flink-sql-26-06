---
prompt: "On Confluent Cloud Flink SQL, I need to enrich streaming orders with customer data from an external Postgres database. Write the lookup join pattern."
model: claude-haiku-4-5
arm: without-skill
date: 2026-05-30
---

# Prompt 03: Lookup Join with PROCTIME

**Prompt:** On Confluent Cloud Flink SQL, I need to enrich streaming orders with customer data from an external Postgres database. Write the lookup join pattern.

**Model:** claude-haiku-4-5
**Arm:** without-skill
**Captured:** 2026-05-30

## Trap

Uses `PROCTIME()` function and `'connector' = 'jdbc'` -- neither exists on Confluent Cloud. CC has no JDBC connector; lookup joins use CC-managed connectors or materialized tables, not direct database connections.

## Response

```sql
CREATE TABLE customers (
  customer_id STRING PRIMARY KEY NOT ENFORCED,
  customer_name STRING,
  email STRING,
  tier STRING,
  proc_time AS PROCTIME()
) WITH (
  'connector' = 'jdbc',
  'url' = 'jdbc:postgresql://host:5432/dbname',
  'table-name' = 'customers',
  'lookup.cache.max-rows' = '10000',
  'lookup.cache.ttl' = '3600s'
);

SELECT o.*, c.customer_name, c.email, c.tier
FROM orders o
LEFT JOIN customers FOR SYSTEM_TIME AS OF o.proc_time AS c
  ON o.customer_id = c.customer_id;
```
