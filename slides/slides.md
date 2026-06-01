---
theme: the-unnamed
title: "CC Flink SQL: Opinions & Surprises"
info: |
  The power of abstractions and opinions - and the surprises that come with them.
  Not about reaching for the stars. About not stubbing your toes.
class: text-center
drawings:
  persist: false
transition: slide-left
mdc: true
---

# SELECT Surprise!
## Discovering CC Flink SQL


<img src="./public/surprise.jpg" class="w-80 mx-auto" />
<div class="text-xl text-gray-400 mt-4">
</div>

---

# Context

<v-clicks>

- My main relevant experience with stream processing: 
  - **Kafka Streams Processor API**
    - API stays out of your way, few assumptions, full control over state, few surprises

  - Some KSQL - rarely a happy story

- **Flink SQL** is different
  - DataStream API exists, but CC doesn't and will not support it
  - Flink SQL is powerful and functional
  - declarative API - **abstracted** & **very opinionated**

</v-clicks>

---

# CC Flink SQL - the opinionated landlord

CC Flink SQL has opinions about:

<v-clicks>

- How your **topics** should be configured
- How your **data** should be serialized and keyed
- When **changes** in your data should be visible
- What you **secretly want** (even if you didn't ask)

</v-clicks>

<div v-click class="mt-8 text-lg text-gray-400">
And maybe it is right...
</div>

---

# The setup

A topic with customer orders. JSON Schema for values, no keys.

```sql
-- bbl-orders: already exists with data
-- order_id, amount, customer_id, order_time
```

<v-clicks>

**Goal:** 

Running aggregation of total order value per customer.

**How hard can it be?**

</v-clicks>

---

# Attempt 1 - Just do it

```sql
CREATE TABLE `bbl-agg-u1`
AS SELECT
  customer_id,
  SUM(amount) total_amount,
  COUNT(*) AS order_count
FROM `bbl-orders` GROUP BY customer_id;
```

Any guesses on what will happen? 

<v-click>

```
Invalid primary key 'PK_customer_id'. Column 'customer_id' is nullable.
```

</v-click>

<v-click>

Yes, the column is optional in the schema.

But I did not specify any keys.

</v-click>

<v-click>

**Opinion #1:** GROUP BY key → auto-becomes PRIMARY KEY. But must be NOT NULL.

</v-click>

---

# Attempt 2 - Make it non-nullable

```sql {3,6}
CREATE TABLE `bbl-agg-u1`
AS SELECT
  COALESCE(customer_id, '') as cust_id,
  SUM(amount) total_amount,
  COUNT(*) AS order_count
FROM `bbl-orders` GROUP BY cust_id;
```

<v-click>

```
Column 'cust_id' not found in any table
```

</v-click>

<v-click>

Not an opinion, just SQL.

Can't reference a SELECT alias in GROUP BY:

</v-click>

---

# Attempt 3 - COALESCE everywhere

```sql {3,6}
CREATE TABLE `bbl-agg-u1`
AS SELECT
  COALESCE(customer_id, '') as cust_id,
  SUM(amount) total_amount,
  COUNT(*) AS order_count
FROM `bbl-orders` GROUP BY COALESCE(customer_id, '');
```

<v-click>

### IT RUNS! 🎉

</v-click>

<v-click>

But wait... let's look at what we got.

</v-click>

---

# Where did my format go?

<v-clicks>

**Opinion #2:** Default format is `avro-registry`, and it will be applied regardless of your source format.

**Opinion #3:** GROUP BY key gets extracted to Kafka message key and removed from the value.

**Opinion #4:** Default format for the key is `avro-registry` too.

</v-clicks>

<v-click>

  <br/>
  <br/>

<figure style="margin-top: 10px">
<img src="./public/monocle.jpeg" class="w-20 mx-auto" />
</figure>

</v-click>

---

# Escaping the Avro - value

```sql {1,4}
CREATE TABLE `bbl-agg-u2` WITH ('value.format' = 'json-registry')
AS SELECT
  COALESCE(customer_id, '') as customer_id,
  customer_id,
  SUM(amount) total_amount,
  COUNT(*) AS order_count
FROM `bbl-orders` GROUP BY COALESCE(customer_id, '');
```

<v-click>

```
Expression 'customer_id' is not being grouped
```

</v-click>

<v-click>

What about duplicating the COALESCE?

```sql
COALESCE(customer_id, '') as customer_id,
COALESCE(customer_id, '') as customer_id,
```
</v-click>

<v-click>
→ Works, but value column becomes `customer_id0` 😬
</v-click>


---

# Getting customer_id back: value.fields-include

```sql {1,2}
CREATE TABLE `bbl-agg-u2` WITH ('value.format' = 'json-registry',
  'value.fields-include' = 'all')
AS SELECT
  COALESCE(customer_id, '') as customer_id,
  SUM(amount) total_amount,
  COUNT(*) AS order_count
FROM `bbl-orders` GROUP BY COALESCE(customer_id, '');
```

<v-clicks>

✅ JSON Schema value - check

✅ `customer_id` in value - check

❌ Key is still Avro - not what we want

</v-clicks>

---

# Escaping the Avro - key

We want a **raw string key** - just the customer ID, no schema.

```sql {1}
WITH ('key.format' = 'raw',...)
```

<v-click>

```
If a key is provided with a 'raw' format it must use 'key' as the column name.
```

</v-click>

<v-click>

**Opinion #5:** Raw keys must be named `key`. Period.

</v-click>

---

# Finally?

```sql
CREATE TABLE `bbl-agg-u5` WITH (
  'key.format' = 'raw',
  'value.format' = 'json-registry')
AS SELECT
  COALESCE(customer_id, '') as key,
  COALESCE(customer_id, '') as customer_id,
  SUM(amount) total_amount,
  COUNT(*) AS order_count
FROM `bbl-orders` GROUP BY COALESCE(customer_id, '');
```

<v-clicks>

✅ Raw string key

✅ JSON Schema value

✅ `customer_id` in both key and value

**5 opinions navigated to get here.**

</v-clicks>

---

# Where are my messages?

```sh
confluent kafka topic consume bbl-agg-u5 \
  --cluster $KAFKA_CLUSTER_ID --from-beginning
```

```
{"customer_id":"c-bob","total_amount":57.0,"order_count":2}
{"customer_id":"c-carol","total_amount":5.0,"order_count":1}
{"customer_id":"c-alice","total_amount":133.99,"order_count":3}
```

<v-click>

<img src="./public/confused.webp" class="w-40 mx-auto" />

6 input records → **3 output records.**

Is it because the topic was compacted?

</v-click>

<v-click>

What happens with more data?

```sh
make flood COUNT=10000 KEYS=3
```

</v-click>

---

# Opinion #6 - batching

With 10,000 input records across 3 customers:

<v-clicks>

- Output topic has **far fewer** than 10,000 records
- Intermediate running totals are **silently discarded**
- Each key only shows the **latest** aggregate
- This is **upsert** behavior - by design

</v-clicks>

<v-click>

**If you wanted a history of running totals - it's gone.**

Can we force append mode instead?

</v-click>

---

# OVER window - append aggregation

```sql
CREATE TABLE `bbl-ctas-over`
DISTRIBUTED BY (`key`)
WITH ('key.format' = 'raw', 'value.format' = 'json-registry')
AS SELECT
  customer_id AS `key`, customer_id, amount,
  SUM(amount) OVER (PARTITION BY customer_id ORDER BY event_time) AS running_total,
  COUNT(*)    OVER (PARTITION BY customer_id ORDER BY event_time) AS order_count
FROM `bbl-orders`;
```

<v-clicks>

<img src="./public/padme.jpg" class="w-40 mx-auto" />

There are duplicates in the count. What's happening?

**`ORDER BY`** - duplicate times -> peer records -> duplicate counts, broken totals.

</v-clicks>

---

# OVER window v2

```sql
CREATE TABLE `bbl-ctas-over-keyed-j3`
DISTRIBUTED BY (`key`)
WITH ('key.format' = 'raw', 'value.format' = 'json-registry')
AS SELECT
  customer_id AS `key`, customer_id, amount,
  SUM(amount) OVER (PARTITION BY customer_id
    ORDER BY event_time
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total,
  COUNT(*) OVER (PARTITION BY customer_id
    ORDER BY event_time
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS order_count
FROM `bbl-orders`;
```

<v-click>

One output row **per input row**. Every intermediate total preserved.

</v-click>

---
  layout: two-cols
---

# how it started

```sql
CREATE TABLE `bbl-agg-u1`
AS SELECT
  customer_id,
  SUM(amount) total_amount,
  COUNT(*) AS order_count
FROM `bbl-orders` GROUP BY customer_id;
```

::right::

# how it is going

```sql
CREATE TABLE `bbl-ctas-over-keyed-j3`
DISTRIBUTED BY (`key`)
WITH ('key.format' = 'raw', 'value.format' = 'json-registry')
AS SELECT
  customer_id AS `key`, customer_id, amount,
  SUM(amount) OVER (PARTITION BY customer_id
    ORDER BY event_time
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total,
  COUNT(*) OVER (PARTITION BY customer_id
    ORDER BY event_time
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS order_count
FROM `bbl-orders`;
```

---
  layout: default
---

# The state growth trap

OVER window preserves every intermediate result. But:

<v-clicks>

- **State grows unbounded** - one entry per row, forever
- Can't see it with 6 records, but at production scale → 💰
- CC Console → Statements → **"State size (GB)"** column
- Query Profiler → per-operator state breakdown

</v-clicks>

<v-clicks>

Can we have append output AND bounded state?

Yes, but at a price.

</v-clicks>

---

# Windowed aggregation

```sql
CREATE TABLE `bbl-ctas-windowed-append`
DISTRIBUTED BY (`key`)
WITH ('key.format' = 'raw', 'value.format' = 'json-registry',
  'value.json-registry.id-encoding' = 'header')
AS SELECT
  COALESCE(customer_id, '') AS `key`,
  window_start, window_end,
  SUM(amount) AS window_total,
  COUNT(*) AS window_count
FROM TABLE(
  TUMBLE(TABLE `bbl-orders`, DESCRIPTOR(event_time),
    INTERVAL '1' MINUTE)
)
GROUP BY window_start, window_end, customer_id;
```

<v-clicks>

✅ Append-only output (each window fires once)

✅ Bounded state (window state discarded after close)

⚠️ No running totals - per-window aggregates only

</v-clicks>

---

# CUMULATE - bounded state and progressive results

What if your window is a day long? Don't wait all day.

```sql
CUMULATE(TABLE `bbl-orders`, DESCRIPTOR(event_time),
  INTERVAL '1' MINUTE,    -- step: emit every 1 min
  INTERVAL '5' MINUTE)    -- max window: 5 min total
```

<v-click>

| Step | window_start | window_end | Covers |
|------|-------------|------------|--------|
| 1 | 10:00 | 10:01 | first minute |
...
| 4 | 10:00 | 10:04 | first 4 minutes |
| 5 | 10:00 | 10:05 | full window |

</v-click>

<v-click>

Append-only. Bounded state. Progressive visibility.

</v-click>

---

# The trade-off summary

| Approach | Append? | Bounded state? | Running totals? |
|----------|---------|----------------|-----------------|
| GROUP BY (non-windowed) | ❌ Upsert | ❌ Grows forever | ✅ Per-key |
| OVER window | ✅ | ❌ Grows forever | ✅ Per-row |
| TUMBLE window | ✅ | ✅ | ❌ Per-window |
| CUMULATE window | ✅ | ✅ | ⚠️ Progressive |

<v-click>

<div style="margin-top: 30px">

### Future: `TO_CHANGELOG` PTF

[FLIP-564](https://cwiki.apache.org/confluence/display/FLINK/FLIP-564) - built-in PTF to escape (or get back to) upsert mode on demand.

</div>
</v-click>

---

# CC Flink SQL and LLMs - the availability bias

<v-clicks>

- LLMs know or find **Apache Flink SQL**
- LLMs do NOT know and do NOT find **Confluent Cloud Flink SQL**
- They look similar. They are not.

</v-clicks>

<v-click>

<img src="./public/sad.jpg" class="w-40 mx-auto" />

</v-click>

---

# Common LLM mistakes on CC

| What LLM generates | What CC actually needs |
|--------------------|-----------------------|
| `GROUP BY TUMBLE(col, INTERVAL)` | `TUMBLE(TABLE t, DESCRIPTOR(col), INTERVAL)` |
| `'value.format' = 'json'` | `'value.format' = 'json-registry'` |
| `PROCTIME()` + JDBC connector | `KEY_SEARCH_AGG` + External Tables |
| Java DataStream API | Java Table API only |
| `'connector' = 'kafka'` | Auto-mapped, no connector property |
| `SET 'table.exec.state.ttl'` | `--property "sql.state-ttl=ms"` |

---

# Claude Code skills to the rescue

A system prompt that encodes CC-specific traps and patterns.

<v-click>

```sh
https://github.com/ksilin/cc-flink-sql-skill
```

</v-click>

<v-click>

<div class="text-sm">
Evals (claude-haiku-4-5, 2 rounds):

| Path | Score | Stability |
|-----|-------|-----------|
| Without skill | **10-20%** | 18/20 stable |
| With skill | **90-95%** | 19/20 stable |
</div>
</v-click>

<v-click>
<div style="margin-top: 40px">
Would it get our aggregate query right? No, it would not. Not yet.
</div>
</v-click>

---

# Live demo

<div class="text-2xl mb-8">
Same prompt. Same model. Only the system prompt differs.
</div>

```sh
# Without skill
echo "prompt" | claude -p --system-prompt "You are a helpful assistant."

# With skill
echo "prompt" | claude -p --system-prompt "$(cat SKILL.md references/*.md)"
```

<v-click>

Let's see it live with 6 prompts...

```sh
make demo-llm
```

</v-click>

---

# My ask

- **Try the skill** on your CC Flink SQL work
- **Let me know** what is missing
- **Even better:** improve it and create a PR

---

# What we didn't cover (yet)

<v-clicks>

- **LAG vs MATCH_RECOGNIZE**
- **Late data handling**
- **UDF processing limitations**
- **Joins** - so many surprises
- **Windowing deeper dive**
- **PTFs**
- **AI/ML**

</v-clicks>

---

# Thank you!

## Questions?
