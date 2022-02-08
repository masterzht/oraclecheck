REM $Header: 215187.1 sqltupgdbahistash.sql 12.1.10 2014/08/08 mauro.pagano $
PRO
PRO This script partitions table SQLT$_DBA_HIST_ACTIVE_SESS_HIS keeping the
PRO historical data. It does require some additional space during the process
PRO Depending on the amount of data stored this operation could take a while
PRO
PRO Requirements:
PRO  1. Connect as SQLTXPLAIN user
PRO  2. Free space on the tablespace where SQLTXPLAIN is stored
PRO
PRO Press ENTER to start
WHENEVER SQLERROR EXIT SQL.SQLCODE;
PAU

SET SERVEROUTPUT ON

DECLARE
 part_type VARCHAR2(10);
 already_partitioned EXCEPTION;
BEGIN
 BEGIN
   SELECT partitioning_type
     INTO part_type
     FROM user_part_tables
    WHERE table_name = 'SQLT$_DBA_HIST_ACTIVE_SESS_HIS';
 EXCEPTION WHEN NO_DATA_FOUND THEN
  part_type := 'NO_PART';
 END;

  IF part_type = 'HASH' THEN 
    raise_application_error(-20001,'Table is already partitioned by HASH, nothing to do!');
  END IF;
END;
/

ALTER TABLE sqlt$_dba_hist_active_sess_his RENAME TO sqlt$_dba_hist_ash_old;

CREATE TABLE sqlt$_dba_hist_active_sess_his PARTITION BY HASH(statement_id) PARTITIONS 32 
AS 
SELECT * FROM sqlt$_dba_hist_ash_old WHERE 1 = 2;

INSERT INTO sqlt$_dba_hist_active_sess_his SELECT * FROM sqlt$_dba_hist_ash_old;
COMMIT;

PRO Process complete, press ENTER to drop the temporary table
PAU
DROP TABLE sqlt$_dba_hist_ash_old;
