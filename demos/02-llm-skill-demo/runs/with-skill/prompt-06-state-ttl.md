---
prompt: "How do I set state TTL for a Flink SQL statement on Confluent Cloud?"
model: claude-haiku-4-5
arm: with-skill
date: 2026-05-30
---

# Prompt 06: State TTL via CLI Property

**Prompt:** How do I set state TTL for a Flink SQL statement on Confluent Cloud?

**Model:** claude-haiku-4-5
**Arm:** with-skill (SKILL.md + reference files)
**Captured:** 2026-05-30

## Key Pattern

Uses `--property` flag on the CLI at statement creation time. `SET 'sql.state-ttl'` as a separate SQL statement is not allowed on CC.

## Response

```bash
confluent flink statement create my-stmt \
  --sql "$(cat query.sql)" \
  --compute-pool <pool-id> --database <cluster-id> --environment <env-id> \
  --property "sql.state-ttl=3600000"
```

Value is in milliseconds. `SET 'sql.state-ttl' = '...'` as a standalone SQL statement is not supported on CC -- must be passed as a CLI property.
