# LLM Skill Demo: With vs Without Skill Comparison

| Metric | Without Skill | With Skill |
|--------|--------------|------------|
| Score (20-prompt eval) | 10-20% (2-4/20) | 90-95% (18-19/20) |
| Model | claude-haiku-4-5 | claude-haiku-4-5 |
| Eval runs | 2 rounds (2026-05-30) | 2 rounds (2026-05-30) |
| Reproducibility | 18/20 stable | 19/20 stable |
| Delta | - | **+70-85%** |

---

## 6 Selected Demo Prompts (100% reproducible across 2 rounds)

### 1. TVF Window Syntax (trap #18)

**Prompt:** Write a Flink SQL tumbling window query that counts vehicle telemetry signals per hour, grouped by vehicle_id. Target runtime is Confluent Cloud.

| Without Skill | With Skill |
|--------------|------------|
| `GROUP BY TUMBLE(recorded_at, INTERVAL '1' HOUR)` | `TUMBLE(TABLE telemetry, DESCRIPTOR(recorded_at), INTERVAL '1' HOUR)` |
| OSS syntax - rejected on CC | CC TVF syntax - correct |

---

### 2. JSON Format (trap #20)

**Prompt:** Write CREATE TABLE DDL for a Flink SQL sink on Confluent Cloud that outputs JSON to a Kafka topic.

| Without Skill | With Skill |
|--------------|------------|
| `'value.format' = 'json'` | `'value.format' = 'json-registry'` |
| Plain JSON - CC rejects | SR-backed format - correct |

---

### 3. PROCTIME / Lookup Join (trap #26)

**Prompt:** Enrich streaming orders with customer data from an external Postgres database on CC Flink SQL.

| Without Skill | With Skill |
|--------------|------------|
| `PROCTIME()` + `'connector' = 'jdbc'` | `KEY_SEARCH_AGG()` + `CREATE CONNECTION` |
| OSS temporal join - neither exists on CC | CC External Tables pattern - correct |

---

### 4. DataStream API (trap #24)

**Prompt:** Write a Confluent Cloud Flink job in Java using the DataStream API to filter Kafka messages.

| Without Skill | With Skill |
|--------------|------------|
| Full Java `StreamExecutionEnvironment` program | "DataStream not supported on CC. Use SQL." |
| 60+ lines of unusable Java code | 3-line SQL filter - correct |

---

### 5. Connector DDL (trap #3)

**Prompt:** Write a CREATE TABLE for a Kafka source in CC Flink SQL with topic 'vehicle-signals' and bootstrap servers.

| Without Skill | With Skill |
|--------------|------------|
| `'connector' = 'kafka'` + `'properties.bootstrap.servers'` | No connector property - auto-mapped from table name |
| OSS connector config - CC doesn't use it | CC auto-mapping - correct |

---

### 6. State TTL (trap #28)

**Prompt:** How do I set state TTL for a Flink SQL statement on Confluent Cloud?

| Without Skill | With Skill |
|--------------|------------|
| `SET 'table.exec.state.ttl' = '10h'` | `--property "sql.state-ttl=3600000"` on CLI |
| OSS property name + SET syntax | CC property name via CLI flag - correct |

---

## Reproduction

Run the full 20-prompt eval harness:

```bash
cd ~/.claude/skills/cc-flink-sql
CC_FLINK_EVAL_MODEL=claude-haiku-4-5 python3 evals/llm_run.py
python3 evals/measure.py
```

Run a single prompt manually (without skill):

```bash
echo "Write a Flink SQL tumbling window query..." \
  | claude -p --disable-slash-commands --output-format text \
  --system-prompt "You are a helpful assistant. Answer the user's question." \
  --model claude-haiku-4-5
```

Run a single prompt manually (with skill):

```bash
echo "Write a Flink SQL tumbling window query..." \
  | claude -p --disable-slash-commands --output-format text \
  --system-prompt "$(cat ~/.claude/skills/cc-flink-sql/SKILL.md ~/.claude/skills/cc-flink-sql/references/*.md)" \
  --model claude-haiku-4-5
```

Run the live demo (all 6 prompts, both arms):

```bash
make demo-llm-run
# or with a different model:
CC_FLINK_EVAL_MODEL=claude-sonnet-4-6 make demo-llm-run
```

Pre-recorded outputs for each prompt are in `runs/without-skill/` and `runs/with-skill/`.
