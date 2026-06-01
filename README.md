# CC Flink SQL: Opinions & Surprises

A talk on Confluent Cloud Flink SQL gotchas, opinionated defaults, and LLM skills.

## Prerequisites

- Confluent CLI (`confluent`) logged in
- Node.js 20+ (for slides)
- A Confluent Cloud environment with compute pool, Kafka cluster, and Schema Registry

## Setup

1. Copy `env.example` to `.env` and fill in your values:

```bash
cp env.example .env
```

2. See all available targets:

```bash
make help
```

## Demo workflow

```bash
make setup                     # create source table + seed data
make flood COUNT=10000 KEYS=3  # produce more data (same 3 customers)
make teardown                  # clean up all CC resources when done
```

Queries are run manually in the CC Flink workspace, following the talking track.

## LLM skill demo

```bash
make demo-llm                                        # 6 prompts, with/without skill
CC_FLINK_EVAL_MODEL=claude-haiku-4-5 make demo-llm  # override model
```

## Slides

```bash
cd slides && npm install      # first time only
make slides-dev               # start dev server at localhost:3030
make slides-build             # build static site
```
