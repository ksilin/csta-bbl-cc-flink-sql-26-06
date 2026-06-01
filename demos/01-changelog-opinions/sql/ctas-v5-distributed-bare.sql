-- CTAS Variant 5: DISTRIBUTED BY only - no WITH clause
--
-- EXPECTED: SUCCEEDS (RUNNING)
--
-- CC auto-decides EVERYTHING:
--   value format:   avro-registry (default)
--   key format:     avro-registry (default)
--   changelog.mode: auto (retract, inferred from GROUP BY)
--   key in value:   NO - customer_id only in key schema
--   key subject:    YES - separate subject in SR (Avro)
--
-- Identical behavior to V4 but with avro-registry for value too.

CREATE TABLE `bbl-ctas-bare-dist`
DISTRIBUTED BY (customer_id)
AS SELECT
  COALESCE(customer_id, '') AS customer_id,
  SUM(amount)  AS total_amount,
  COUNT(*)     AS order_count
FROM `bbl-orders`
GROUP BY customer_id;
