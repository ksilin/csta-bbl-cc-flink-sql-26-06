-- CTAS Variant 1: Bare - no WITH, no DISTRIBUTED BY, no COALESCE
--
-- EXPECTED: FAILS - "Invalid primary key 'PK_customer_id'. Column 'customer_id' is nullable."
--
-- CC auto-infers PK from GROUP BY key, auto-selects upsert changelog mode.
-- But customer_id is STRING (nullable) - PK requires NOT NULL.
-- The framework is opinionated: it WANTS a PK, but can't make a nullable column non-null.

CREATE TABLE `bbl-ctas-bare` AS
SELECT
  customer_id,
  SUM(amount)  AS total_amount,
  COUNT(*)     AS order_count
FROM `bbl-orders`
GROUP BY customer_id;
