# CC Flink SQL Talk - Opinions, Surprises, and LLM Skills

ifneq (,$(wildcard .env))
  include .env
  export
endif

.DEFAULT_GOAL := help

COUNT ?= 1000
KEYS ?= $(COUNT)

.PHONY: help setup teardown flood demo-llm slides-dev slides-build

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

## Demo Setup & Data

setup: ## Create bbl-orders source table and produce initial data
	@bash demos/01-changelog-opinions/setup.sh

teardown: ## Drop all demo tables and delete topics
	@bash demos/01-changelog-opinions/teardown.sh

flood: ## Produce COUNT records into bbl-orders (default 1000, KEYS=distinct customer IDs)
	@bash scripts/produce-orders.sh --topic bbl-orders --count $(COUNT) --keys $(KEYS)

## LLM Skill Demo

demo-llm: ## Live side-by-side - same prompt, with/without skill
	@bash demos/02-llm-skill-demo/run.sh

## Slides

slides/node_modules/.package-lock.json: slides/package.json
	@cd slides && npm install

slides-install: slides/node_modules/.package-lock.json ## Install Slidev dependencies

slides-dev: slides-install ## Start Slidev dev server (localhost:3030)
	@cd slides && npm run dev

slides-build: slides-install ## Build slides as static web app
	@cd slides && npm run build
