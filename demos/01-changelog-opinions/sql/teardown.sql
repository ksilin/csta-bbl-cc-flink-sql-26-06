-- teardown.sql - CC Flink SQL Talk: changelog opinions demo
-- Drops all three tables created by setup.sql.
-- Sinks dropped before source (dependency ordering).
-- DROP TABLE IF EXISTS is idempotent - safe to re-run.
--
-- IMPORTANT: This file is only run at the END of the demo (after both broken and fixed phases).
-- Do NOT drop tables between the broken and fixed phases - that would delete the source topic.

DROP TABLE IF EXISTS `bbl-agg-upsert`;
DROP TABLE IF EXISTS `bbl-agg-append`;
DROP TABLE IF EXISTS `bbl-orders`;
