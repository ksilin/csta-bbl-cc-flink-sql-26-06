-- CTAS Variant 2: COALESCE - makes GROUP BY key non-nullable
--
-- EXPECTED: SUCCEEDS (RUNNING)
--
-- COALESCE(customer_id, '') returns STRING NOT NULL - satisfies PK requirement.
-- CC auto-decides everything:
--   format:         avro-registry (both key and value)
--   changelog.mode: retract (inferred from GROUP BY producing updates)
--   PK:             customer_id (inferred from GROUP BY)
--   key in value:   YES - customer_id appears in value schema (no DISTRIBUTED BY to separate it)
--   key subject:    NO separate key subject in Schema Registry

CREATE TABLE `bbl-ctas-coalesce` AS
SELECT
  COALESCE(customer_id, '') AS customer_id,
  SUM(amount)  AS total_amount,
  COUNT(*)     AS order_count
FROM `bbl-orders`
GROUP BY customer_id;
