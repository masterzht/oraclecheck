SELECT v.customer_name,
       v.orders_total,
       v.credit_limit,
       (orders_total - credit_limit) over_limit
  FROM customer_v v
 WHERE orders_total > credit_limit
   AND customer_type = :b1
 ORDER BY
       over_limit DESC;
