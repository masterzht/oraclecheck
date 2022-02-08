SELECT s1.channel_id,
       SUM(p.prod_list_price) price
  FROM products p,
       sales s1,
       sales s2
 WHERE s1.cust_id = :b1
   AND s1.prod_id = p.prod_id
   AND s1.time_id = s2.time_id
 GROUP BY
       s1.channel_id;
