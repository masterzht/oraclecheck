VAR b1 VARCHAR2(1);
EXEC :b1 := '4';

SELECT /*+ gather_plan_statistics monitor bind_aware */
       v.customer_name,
       v.orders_total,
       v.credit_limit,
       (orders_total - credit_limit) over_limit
  FROM customer_v v
 WHERE orders_total > credit_limit
   AND customer_type = :b1
 ORDER BY
       over_limit DESC;
