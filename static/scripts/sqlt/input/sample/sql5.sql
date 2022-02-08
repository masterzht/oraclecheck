with
tsales as
(
select /*+ gather_plan_statistics monitor */
s.quantity_sold
, s.amount_sold
, to_char(mod(cust_year_of_birth,10) * 10 ) || '-' ||
to_char((mod(cust_year_of_birth,10) * 10 ) + 10) age_range
, nvl(c.cust_income_level,'A: Below 30,000') cust_income_level
, p.prod_name
, p.prod_desc
, p.prod_category
, (pf.unit_cost * s.quantity_sold) total_cost
, s.amount_sold - (pf.unit_cost * s.quantity_sold) profit
from sh.sales s
join sh.customers c on c.cust_id = s.cust_id
join sh.products p on p.prod_id = s.prod_id
join sh.times t on t.time_id = s.time_id
join sh.costs pf on
pf.channel_id = s.channel_id
and pf.prod_id = s.prod_id
and pf.promo_id = s.promo_id
and pf.time_id = s.time_id
where(t.fiscal_year = 2001)
)
select
'Q' || decode(cust_income_level,
null,decode(age_range,null,4,3),
decode(age_range,null,2,1)
) query_tag
, prod_category
, cust_income_level
, age_range
, sum(profit) profit
from tsales
group by prod_category, cube(cust_income_level,age_range)
order by prod_category, profit
;
/
/
