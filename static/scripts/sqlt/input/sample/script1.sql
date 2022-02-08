REM Sample SCRIPT to be used as input to sqltxecute.sql
REM

-- execute sqlt xecute as sh passing script name
-- cd sqlt
-- #sqlplus sh
-- SQL> start run/sqltxecute.sql input/sample/script1.sql

REM Optional ALTER SESSION commands
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

--ALTER SESSION SET statistics_level = ALL;

REM Optional Binds
REM ~~~~~~~~~~~~~~

VAR b1 NUMBER;
EXEC :b1 := 10;

REM SQL statement to be executed
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SELECT /*+ gather_plan_statistics monitor bind_aware */
       /* ^^unique_id */
       s1.channel_id,
       SUM(p.prod_list_price) price
  FROM products p,
       sales s1,
       sales s2
 WHERE s1.cust_id = :b1
   AND s1.prod_id = p.prod_id
   AND s1.time_id = s2.time_id
 GROUP BY
       s1.channel_id;
/
/

REM Notes:
REM 1. SQL must contain token: /* ^^unique_id */
REM 2. Do not replace ^^unique_id with your own tag.
REM 3. SQL may contain CBO Hints, like:
REM    /*+ gather_plan_statistics monitor bind_aware */
