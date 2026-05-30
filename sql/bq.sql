-- BigQuery: customer lifetime value with nested types
SELECT
  c.customer_id,
  c.customer_name,
  ARRAY_AGG(DISTINCT o.product_category ORDER BY o.product_category) AS categories,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), MAX(o.created_at), DAY)        AS days_since_order,
  SUM(o.amount)                                                       AS lifetime_value,
  IFNULL(c.loyalty_tier, 'standard')                                  AS tier,
  SAFE_CAST(c.discount_code AS INT64)                                 AS discount_int,
  REGEXP_CONTAINS(c.email, r'^[\w._%+\-]+@[\w.\-]+\.[a-z]{2,}$') AS valid_email,
  IF(SUM(o.amount) > 5000, 'vip', 'standard')                        AS segment
FROM `myproject.crm.customers` c
LEFT JOIN `myproject.crm.orders` o USING (customer_id)
WHERE DATE_TRUNC(o.created_at, MONTH) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
  AND o.status = 'completed'
QUALIFY ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.created_at DESC) = 1
GROUP BY 1, 2, c.loyalty_tier, c.email, c.discount_code
ORDER BY lifetime_value DESC
LIMIT 1000;
