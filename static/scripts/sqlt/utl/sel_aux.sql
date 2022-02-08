REM $Header: utl/sel_aux.sql 11.4.4.2 2012/02/02 carlos.sierra $
REM Computes predicate selectivity using CBO. Requires sel.sql.
PRO
ACC predicate PROMPT 'Predicate for &&table.: ';
DELETE plan_table;
EXPLAIN PLAN FOR SELECT /*+ FULL(t) */ COUNT(*) FROM &&table. t WHERE &&predicate.;
SELECT MAX(cardinality) e_rows FROM plan_table;
SELECT &&e_rows. "Comp Card", ROUND(&&e_rows./&&table_rows., 12) selectivity FROM DUAL;
@@sel_aux.sql
