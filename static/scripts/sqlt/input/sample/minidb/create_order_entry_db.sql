CONN &&user./&&user.

DEF customers           = 1e5;
DEF parts               = 2e5;
DEF sales_orders        = 3e5;
DEF max_lines_per_order = 20;

PURGE RECYCLEBIN;
EXEC DBMS_RANDOM.SEED(0);

/************************************************************************/

DROP TABLE customer;
CREATE TABLE customer AS
WITH v1 AS (SELECT ROWNUM n FROM dual CONNECT BY LEVEL <= 10000)
SELECT ROWNUM customer_id,
       DBMS_RANDOM.STRING('U', 40) customer_name,
       TO_CHAR(ABS(ROUND(DBMS_RANDOM.NORMAL)) + 1) customer_type,
       CASE WHEN MOD(ROWNUM, 7) > 0 THEN ROUND(DBMS_RANDOM.VALUE(1, 101)) * 1000 END credit_limit
  FROM v1, v1
 WHERE ROWNUM <= &&customers.;

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'customer');

ALTER TABLE customer MODIFY (customer_id NOT NULL);
ALTER TABLE customer MODIFY (customer_type NOT NULL);

CREATE UNIQUE INDEX customer_pk ON customer (customer_id);
ALTER TABLE customer ADD (CONSTRAINT customer_pk PRIMARY KEY (customer_id));

CREATE INDEX customer_n1 ON customer (customer_name);

CREATE INDEX customer_n2 ON customer (customer_type, credit_limit);

CREATE INDEX customer_f1 ON customer (LOWER(customer_name));

/************************************************************************/

DROP TABLE part;
CREATE TABLE part AS
WITH v1 AS (SELECT ROWNUM n FROM dual CONNECT BY LEVEL <= 10000)
SELECT ROWNUM part_id,
       DBMS_RANDOM.STRING('X', 30) part_name,
       CHR(ROUND(DBMS_RANDOM.NORMAL) + 70) part_type,
       ABS(ROUND(DBMS_RANDOM.NORMAL * 1000, 2)) part_price,
       ABS(ROUND(DBMS_RANDOM.NORMAL)) on_hand
  FROM v1, v1
 WHERE ROWNUM <= &&parts.;

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'part');

ALTER TABLE part MODIFY (part_id NOT NULL);
ALTER TABLE part MODIFY (part_type NOT NULL);
ALTER TABLE part MODIFY (part_price NOT NULL);

CREATE UNIQUE INDEX part_pk ON part (part_id);
ALTER TABLE part ADD (CONSTRAINT part_pk PRIMARY KEY (part_id));

CREATE INDEX part_n1 ON part (part_name);

DECLARE
  cg_name VARCHAR2(30);
BEGIN
 cg_name := DBMS_STATS.CREATE_EXTENDED_STATS(USER, 'part', '(part_type, on_hand)');
END;
/
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'part', method_opt => 'FOR ALL HIDDEN COLUMNS');

/************************************************************************/

DROP TABLE sales_order;
CREATE TABLE sales_order AS
WITH v1 AS (SELECT ROWNUM n FROM dual CONNECT BY LEVEL <= 10000)
SELECT ROWNUM order_id,
       DBMS_RANDOM.STRING('U', 1)||DBMS_RANDOM.STRING('U', 1)||LPAD(ROUND(DBMS_RANDOM.VALUE(1, 1e12)), 12, '0') order_num,
       ROUND(SYSDATE - DBMS_RANDOM.VALUE(0, 1001)) order_date,
       ROUND(DBMS_RANDOM.VALUE(1, &&customers.)) customer_id,
       CHR(ROUND(DBMS_RANDOM.NORMAL) + 85) status
  FROM v1, v1
 WHERE ROWNUM <= &&sales_orders.;

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'sales_order');

ALTER TABLE sales_order MODIFY (order_id NOT NULL);
ALTER TABLE sales_order MODIFY (order_num NOT NULL);
ALTER TABLE sales_order MODIFY (customer_id NOT NULL);

CREATE UNIQUE INDEX sales_order_pk ON sales_order (order_id);
ALTER TABLE sales_order ADD (CONSTRAINT sales_order_pk PRIMARY KEY (order_id));

CREATE INDEX sales_order_n1 ON sales_order (order_num);
CREATE INDEX sales_order_n2 ON sales_order (customer_id, order_date);

DECLARE
  ex_name VARCHAR2(30);
BEGIN
 ex_name := DBMS_STATS.CREATE_EXTENDED_STATS(USER, 'sales_order', '(SUBSTR(order_num, 1, 2))');
END;
/
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'sales_order', method_opt => 'FOR ALL HIDDEN COLUMNS');

/************************************************************************/

DROP TABLE order_line;
CREATE TABLE order_line (
  line_id       NUMBER NOT NULL,
  order_id      NUMBER NOT NULL,
  line_num      NUMBER NOT NULL,
  part_id       NUMBER NOT NULL,
  quantity      NUMBER NOT NULL,
  discount_perc NUMBER
);

DECLARE
  my_line_id INTEGER := 0;
BEGIN
  FOR i IN 1 .. &&sales_orders.
  LOOP
    FOR j IN 1 .. ROUND(DBMS_RANDOM.VALUE(1, &&max_lines_per_order.) + 1)
    LOOP
      my_line_id := my_line_id + 1;
      INSERT INTO order_line (
        line_id,
        order_id,
        line_num,
        part_id,
        quantity,
        discount_perc
      ) VALUES (
        my_line_id,
        ROUND(DBMS_RANDOM.VALUE(1, &&sales_orders.)),
        j,
        ROUND(DBMS_RANDOM.VALUE(1, &&parts.)),
        ABS(ROUND(DBMS_RANDOM.NORMAL * 10) + 1),
        CASE WHEN MOD(my_line_id, 5) = 0 THEN ROUND(DBMS_RANDOM.VALUE(1, 11)) * 5 END
      );
    END LOOP;
    COMMIT;
  END LOOP;
END;
/

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'order_line');

CREATE UNIQUE INDEX order_line_pk ON order_line (line_id);
ALTER TABLE order_line ADD (CONSTRAINT order_line_pk PRIMARY KEY (line_id));

CREATE INDEX order_line_n1 ON order_line (order_id);
CREATE INDEX order_line_n2 ON order_line (part_id);

ALTER TABLE order_line ADD CONSTRAINT order_fk FOREIGN KEY (order_id) REFERENCES sales_order (order_id);
ALTER TABLE order_line ADD CONSTRAINT part_fk FOREIGN KEY (part_id) REFERENCES part (part_id);

/************************************************************************/

CREATE OR REPLACE VIEW part_v AS
SELECT p.part_id,
       p.part_name,
       p.part_type,
       p.part_price,
       p.on_hand,
       l.order_id,
       l.line_num,
       l.quantity,
       l.discount_perc,
       ROUND(l.quantity * p.part_price * (100 - NVL(l.discount_perc, 0)) / 100, 2) sales_price,
       (SELECT /*+ QB_NAME (cust_name_qb) */
               c.customer_name
          FROM sales_order o,
               customer    c
         WHERE o.order_id    = l.order_id
           AND o.customer_id = c.customer_id) customer_name
  FROM part       p,
       order_line l
 WHERE p.part_id = l.part_id;

/************************************************************************/

CREATE OR REPLACE VIEW order_line_v AS
SELECT o.customer_id,
       c.customer_name,
       c.customer_type,
       l.order_id,
       o.order_num,
       o.order_date,
       o.status,
       l.line_id,
       l.line_num,
       l.part_id,
       p.part_name,
       p.part_type,
       p.part_price,
       l.quantity,
       l.discount_perc,
       ROUND(l.quantity * p.part_price * (100 - NVL(l.discount_perc, 0)) / 100, 2) sales_price
  FROM order_line  l,
       part        p,
       sales_order o,
       customer    c
 WHERE l.order_id    = o.order_id
   AND o.customer_id = c.customer_id
   AND l.part_id     = p.part_id;

/************************************************************************/

CREATE OR REPLACE VIEW sales_order_v AS
SELECT o.customer_id,
       c.customer_name,
       c.customer_type,
       c.credit_limit,
       o.order_num,
       o.order_date,
       o.status,
       lines_total.order_lines,
       lines_total.items_total,
       lines_total.order_total
  FROM sales_order o,
       customer    c,
       (SELECT /*+ QB_NAME (lines_rollup_qb) */
               l.order_id,
               COUNT(*) order_lines,
               SUM(l.quantity) items_total,
               SUM(ROUND(l.quantity * p.part_price * (100 - NVL(l.discount_perc, 0)) / 100, 2)) order_total
          FROM order_line l,
               part       p
         WHERE l.part_id = p.part_id
         GROUP BY
               l.order_id) lines_total
 WHERE o.customer_id = c.customer_id
   AND o.order_id    = lines_total.order_id;

/************************************************************************/

CREATE OR REPLACE VIEW customer_v AS
SELECT c.customer_id,
       c.customer_name,
       c.customer_type,
       c.credit_limit,
       orders.orders_count,
       orders.orders_total
  FROM customer c,
       (SELECT /*+ QB_NAME (open_orders_rollup_qb) */
               o.customer_id,
               COUNT(*) orders_count,
               SUM(o.order_total) orders_total
          FROM sales_order_v o
         WHERE o.status NOT IN ('C', 'S')
         GROUP BY
               o.customer_id) orders
 WHERE c.customer_id = orders.customer_id;

/************************************************************************/
