---
prompt: "Write a Confluent Cloud Flink job in Java using the DataStream API to filter Kafka messages by vehicle_id."
model: claude-haiku-4-5
arm: with-skill
date: 2026-05-30
---

# Prompt 04: DataStream API Refusal

**Prompt:** Write a Confluent Cloud Flink job in Java to filter Kafka messages by vehicle_id.

**Model:** claude-haiku-4-5
**Arm:** with-skill (SKILL.md + reference files)
**Captured:** 2026-05-30

## Key Pattern

Correctly refuses the DataStream API request -- CC supports Table API / SQL only.

## Response

DataStream API is not supported on Confluent Cloud Flink. CC supports the Table API (SQL) only. Use SQL instead:

```sql
INSERT INTO filtered_telemetry
SELECT * FROM telemetry_signals
WHERE vehicle_id = 'VEHICLE_123';
```
