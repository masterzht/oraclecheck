REM $Header: sqcparameters.sql 12.1.160429 2016/04/29 carlos.sierra mauro.pagano abel.macias@oracle.com $
SET TERM ON;
PRO
PRO Specify optional Connect Identifier (as per Oracle Net)
PRO Include "@" symbol, ie. @PROD
PRO If not applicable, enter nothing and hit the "Enter" key.
PRO You *MUST* provide a connect identifier when installing
PRO SQLT in a Pluggable Database in 12c
PRO This connect identifier is only used while exporting SQLT
PRO repository everytime you execute one of the main methods.
PRO
ACC connect_identifier PROMPT 'Optional Connect Identifier (ie: @PROD): ';
PRO
@@sqcval1.sql

/*------------------------------------------------------------------*/

PRO
PRO Define SQLTXPLAIN password (hidden and case sensitive).
SET HEAD OFF
SELECT CASE WHEN count(*) > 0 THEN 'The system has a password complexity function defined, make sure to provide a valid password.' ELSE '' END
  FROM dba_profiles
 WHERE resource_name = 'PASSWORD_VERIFY_FUNCTION'
   AND limit <> 'NULL'
   AND profile = 'DEFAULT';
SET HEAD ON
PRO
ACC enter_tool_password PROMPT 'Password for user SQLTXPLAIN: ' HIDE;
ACC re_enter_password PROMPT 'Re-enter password: ' HIDE;
PRO
@@sqcval2.sql

/*------------------------------------------------------------------*/
/* 160426 New */

PRO
PRO The next step is to choose the tablespaces to be used by SQLTXPLAIN
PRO
PRO The Tablespace name is case sensitive.
PRO
PRO Do you want to see the free space of each tablespace [YES]
PRO or is it ok just to show the list of tablespace [NO]?
PRO
ACC free_space PROMPT 'Type YES or NO [Default NO]: ';
PRO
PRO ... please wait

WITH f AS (
        SELECT tablespace_name, NVL(ROUND(SUM(bytes)/1024/1024), 0) free_space_mb
          FROM (SELECT tablespace_name, SUM( bytes ) bytes 
                  FROM sys.dba_free_space 
                GROUP BY tablespace_name
                UNION ALL
                SELECT tablespace_name, SUM( maxbytes - bytes ) bytes 
                  FROM sys.dba_data_files 
                 WHERE maxbytes - bytes > 0 
                GROUP BY tablespace_name )
         GROUP BY tablespace_name)
SELECT t.tablespace_name, f.free_space_mb
  FROM sys.dba_tablespaces t, f
WHERE t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND t.status = 'ONLINE'
   AND t.contents = 'PERMANENT'
   AND t.tablespace_name = f.tablespace_name
   AND f.free_space_mb > 50
   AND  nvl(upper('&&free_space'),'NO')='YES'
UNION   
select tablespace_name,null from dba_tablespaces t
 where t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND t.status = 'ONLINE'
   AND t.contents = 'PERMANENT'  
   AND nvl(upper('&&free_space'),'NO')<>'YES' 
ORDER BY 2,1;

UNDEF free_space

PRO
PRO Specify PERMANENT tablespace to be used by SQLTXPLAIN.
PRO
PRO Tablespace name is case sensitive.
PRO
ACC default_tablespace PROMPT 'Default tablespace [&&prior_default_tablespace.]: ';
@@sqcval3.sql

/*------------------------------------------------------------------*/

PRO ... please wait

SELECT t.tablespace_name
  FROM sys.dba_tablespaces t
 WHERE t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND t.status = 'ONLINE'
   AND t.contents = 'TEMPORARY'
   AND NOT EXISTS (
SELECT NULL
  FROM sys.dba_tablespace_groups tg
 WHERE t.tablespace_name = tg.tablespace_name )
 UNION
SELECT tg.group_name
  FROM sys.dba_tablespaces t,
       sys.dba_tablespace_groups tg
 WHERE t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND t.status = 'ONLINE'
   AND t.contents = 'TEMPORARY'
   AND t.tablespace_name = tg.tablespace_name;

PRO
PRO Specify TEMPORARY tablespace to be used by SQLTXPLAIN.
PRO
PRO Tablespace name is case sensitive.
PRO
ACC temporary_tablespace PROMPT 'Temporary tablespace [&&prior_temporary_tablespace.]: ';
@@sqcval4.sql

/*------------------------------------------------------------------*/

PRO
PRO The main application user of SQLT is the schema
PRO owner that issued the SQL to be analyzed.
PRO For example, on an EBS application you would
PRO enter APPS.
PRO You will not be asked to enter its password.
PRO To add more SQLT users after this installation
PRO is completed simply grant them the SQLT_USER_ROLE
PRO role.
PRO
ACC main_application_schema PROMPT 'Main application user of SQLT: ';
@@sqcval5.sql

/*------------------------------------------------------------------*/

PRO
PRO SQLT can make extensive use of licensed features
PRO provided by the Oracle Diagnostic and the Oracle
PRO Tuning Packs, including SQL Tuning Advisor (STA),
PRO SQL Monitoring and Automatic Workload Repository
PRO (AWR).
PRO To enable or disable access to these features
PRO from the SQLT tool enter one of the following
PRO values when asked:
PRO
PRO "T" if you have license for Diagnostic and Tuning
PRO "D" if you have license only for Oracle Diagnostic
PRO "N" if you do not have these two licenses
PRO
ACC pack_license PROMPT 'Oracle Pack license [T]: ';
@@sqcval6.sql

/*------------------------------------------------------------------*/
