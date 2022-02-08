REM $Header: sqcval0.sql 11.4.5.0 2012/11/21 carlos.sierra $

COL connect_identifier NEW_VALUE connect_identifier FOR A80;
COL prior_default_tablespace NEW_VALUE prior_default_tablespace FOR A30;
COL prior_temporary_tablespace NEW_VALUE prior_temporary_tablespace FOR A30;
COL tablespace_name FOR A30 HEA "TABLESPACE";
COL default_tablespace NEW_VALUE default_tablespace FOR A30;
COL temporary_tablespace NEW_VALUE temporary_tablespace FOR A30;
COL application_schema NEW_VALUE application_schema FOR A30;

SELECT 'UNKNOWN' prior_default_tablespace,
       'UNKNOWN' prior_temporary_tablespace
  FROM dual;

SELECT default_tablespace prior_default_tablespace,
       temporary_tablespace prior_temporary_tablespace
  FROM sys.dba_users
 WHERE username = '&&tool_repository_schema.';

/*------------------------------------------------------------------*/
