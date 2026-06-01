-- CTAS Variant 4: DISTRIBUTED BY + explicit json-registry
--
-- EXPECTED: SUCCEEDS (RUNNING)
--
-- DISTRIBUTED BY routes customer_id to Kafka message key.
-- CC auto-decides:
--   value format:   json-registry (as specified)
--   key format:     avro-registry (DEFAULT - not json-registry!)
--   changelog.mode: auto (retract, inferred from GROUP BY)
--   key in value:   NO - customer_id REMOVED from value schema, lives only in key
--   key subject:    YES - separate bbl-ctas-distributed-key subject in SR (Avro)

CREATE TABLE `bbl-ctas-distributed`
DISTRIBUTED BY (customer_id)
WITH ('value.format' = 'json-registry')
AS SELECT
  COALESCE(customer_id, '') AS customer_id,
  SUM(amount)  AS total_amount,
  COUNT(*)     AS order_count
FROM `bbl-orders`
GROUP BY customer_id;
