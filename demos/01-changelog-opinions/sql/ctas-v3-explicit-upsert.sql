-- CTAS Variant 3: Explicit upsert in WITH clause
--
-- EXPECTED: FAILS - "An upsert table requires a PRIMARY KEY constraint."
--
-- Paradox: CC infers PK from GROUP BY for bare CTAS (V2), but when you
-- explicitly say changelog.mode=upsert, it demands explicit PK declaration.
-- CTAS can't declare PRIMARY KEY in its schema - only regular CREATE TABLE can.
-- You can't have it both ways: explicit upsert + CTAS = error.

CREATE TABLE `bbl-ctas-explicit-upsert`
WITH ('value.format' = 'json-registry', 'changelog.mode' = 'upsert')
AS SELECT
  COALESCE(customer_id, '') AS customer_id,
  SUM(amount)  AS total_amount,
  COUNT(*)     AS order_count
FROM `bbl-orders`
GROUP BY customer_id;
