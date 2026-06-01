-- setup.sql - CC Flink SQL Talk: changelog opinions demo
-- Three tables: source, intentionally-wrong append sink, and correct upsert sink.
-- All three are created here and all three are dropped in teardown.sql.

CREATE TABLE `bbl-orders` (
  order_id     STRING,
  amount       DOUBLE,
  customer_id  STRING,
  order_time   STRING,
  event_time   AS TO_TIMESTAMP(order_time),
  WATERMARK FOR event_time AS event_time - INTERVAL '5' SECOND
) WITH (
  'changelog.mode' = 'append',
  'value.format'   = 'json-registry'
);

-- Intentionally wrong sink: append mode cannot accept update/delete events.
-- broken.sql targets this table and will fail with:
--   "Table sink 'bbl-agg-append' doesn't support consuming update and delete changes"
CREATE TABLE `bbl-agg-append` (
  customer_id  STRING,
  total_amount DOUBLE,
  order_count  BIGINT
) WITH (
  'changelog.mode' = 'append',
  'value.format'   = 'json-registry'
);

-- Correct sink: upsert mode with PRIMARY KEY NOT ENFORCED.
-- fixed.sql targets this table and succeeds.
CREATE TABLE `bbl-agg-upsert` (
  customer_id  STRING NOT NULL,
  total_amount DOUBLE,
  order_count  BIGINT,
  PRIMARY KEY (customer_id) NOT ENFORCED
) WITH (
  'changelog.mode' = 'upsert',
  'value.format'   = 'json-registry'
);
