---
prompt: "On Confluent Cloud Flink SQL, I need to enrich streaming orders with customer data from an external Postgres database. Write the lookup join pattern."
model: claude-haiku-4-5
arm: with-skill
date: 2026-05-30
---

# Prompt 03: Lookup Join Without PROCTIME()

**Prompt:** On Confluent Cloud Flink SQL, I need to enrich streaming orders with customer data from an external Postgres database. Write the lookup join pattern.

**Model:** claude-haiku-4-5
**Arm:** with-skill (SKILL.md + reference files)
**Captured:** 2026-05-30

## Key Pattern

Uses `KEY_SEARCH_AGG` + External Tables via `confluent-jdbc` connector. Avoids `PROCTIME()` which does not exist on CC.

## Response

```sql
CREATE CONNECTION postgres_customers
  WITH ('type' = 'confluent_jdbc', ...);

CREATE TABLE customers (...) WITH (
    'connector' = 'confluent-jdbc',
    'confluent-jdbc.connection' = 'postgres_customers',
    'confluent-jdbc.table-name' = 'customers'
);

SELECT o.*, c.customer_name, c.email, c.tier
FROM orders o,
LATERAL TABLE(KEY_SEARCH_AGG(customers, DESCRIPTOR(customer_id), o.customer_id)) AS lookup,
CROSS JOIN UNNEST(lookup.search_results) AS c(...);
```

`PROCTIME()` doesn't exist on CC. Note the underscore in connection type (`confluent_jdbc`) vs hyphen in connector (`confluent-jdbc`).
