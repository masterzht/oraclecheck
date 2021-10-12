-- 'd better set them at glogin.sql
col temporary_tablespace format a30
col default_tablespace format a30
col username format a30
col table_name format a30
col segment_name format a30
col column_name format a30

set pages 1000
set lines 135
set time on 
set timing on 
set arraysize 100
set long 20000 longchunksize 100000000
set serveroutput on size 10000
/* trimspool will trim the blank space at the end of lines when using spool command */
set trimspool on
define _EDITOR=vi
define user_name=""
define instance_name=""

SET TERMOUT OFF
COLUMN user_name NEW_VALUE user_name
COLUMN instance_name NEW_VALUE instance_name
alter session set nls_date_format ='yyyy-mm-dd hh24:mi:ss';
alter session set statistics_level=all;
alter session set max_dump_file_size=unlimited;
alter session set events '10046 trace name context forever, level 12';
prompt alter session set statistics_level=all;
prompt alter session set max_dump_file_size = UNLIMITED;
prompt alter session set events '10046 trace name context forever, level 12';
prompt alter session set events '10046 trace name context off';
prompt alter session set events '10053 trace name context forever, level 1';
prompt alter session set events '10053 trace name context off';
SELECT lower(user) user_name,
       decode(instr(global_name,'.'),0,global_name,
              substr(global_name,1,instr(global_name,'.')-1 )) instance_name
  FROM global_name;
SET SQLPROMPT '&user_name@&instance_name>'
SET TERM ON

spool ./log/sqlplus.log append
