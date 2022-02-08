REM Displays plan for most recently executed SQL. Just execute "@plan.sql" from sqlplus.
SET PAGES 2000 LIN 180;
SPO plan.txt;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL,TO_NUMBER(NULL),'ADVANCED RUNSTATS_LAST'));
SPO OFF;
