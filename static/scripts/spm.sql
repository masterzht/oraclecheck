set serveroutput on 
set verify off
set timing off
set linesize 500
set pages 0

undefine table_name
undefine owner
var table_name varchar2(100);
var owner varchar2(100);

begin
  :owner :=upper('&owner');
  :table_name := upper('&table_name');
end;
/

--alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
declare
    cursor c_spm is SELECT 
       s.SQL_HANDLE,
       s.PLAN_NAME,
       s.ENABLED,
       s.ACCEPTED,
       s.FIXED,
       s.OPTIMIZER_COST,
       to_char(s.CREATED,'yyyymmdd hh24:mi:ss') as created,
       decode(to_char(s.last_verified,'yyyymmdd hh24:mi:ss'),null,'None',to_char(s.last_verified,'yyyymmdd hh24:mi:ss') ) as last_verified,
       s.SQL_TEXT
  FROM DBA_SQL_PLAN_BASELINES s
  WHERE s.PARSING_SCHEMA_NAME = :owner order by s.SQL_HANDLE,s.OPTIMIZER_COST desc;
    v_spm c_spm%rowtype;

begin


    dbms_output.put_line('
Display SQL Plan Baseline Information from dba_sql_plan_baselines');
  dbms_output.put_line('======================');
  dbms_output.put_line('------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| SQL_HANDLE           |' || ' PLAN_NAME                      ' || '| ENABLED |' || ' ACCEPTED ' || '| FIXED |' || ' OPT_COST ' || '| CREATED           '  || '| LAST_VERIFIED     |'|| ' SQL_TEXT                     '|| '|');
  dbms_output.put_line('------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_spm;
    loop fetch c_spm into v_spm;
    exit when c_spm%notfound;
    dbms_output.put_line('| ' || rpad(v_spm.SQL_HANDLE,20) ||' | '|| rpad(v_spm.PLAN_NAME,30) || ' | '|| lpad(v_spm.ENABLED,7) || ' | '|| lpad(v_spm.ACCEPTED,8) || ' | '|| lpad(v_spm.FIXED,5) || ' | '|| lpad(v_spm.OPTIMIZER_COST,8) ||  ' | '|| rpad(v_spm.created,17) || ' | '|| rpad(v_spm.last_verified,17) || ' | '|| rpad(v_spm.SQL_TEXT,28)||' |');
    end loop;
    dbms_output.put_line('------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_spm;
/**

  dbms_output.put_line('
Shared Pool Sub Pool Size Information');
  dbms_output.put_line('======================');
  dbms_output.put_line('---------------------------------------------------------------');
  dbms_output.put_line('| SUBPOOL                |' || ' SUBPOOL_BYTES         ' || '| SUBPOOL_MB ' || '|');
  dbms_output.put_line('---------------------------------------------------------------');
  open c_sub;
    loop fetch c_sub into v_sub;
    exit when c_sub%notfound;
    dbms_output.put_line('| ' || rpad(v_sub.subpool,22) ||' | '|| lpad(v_sub.bytes,21) || ' | '|| lpad(v_sub.MB,10) || ' |');
    end loop;
    dbms_output.put_line('---------------------------------------------------------------');
  close c_sub;

  dbms_output.put_line('
Shared Pool Sub Pool components Detail Information');
  dbms_output.put_line('======================');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| RANK |' || ' SUBPOOL                |' || ' COMPONENT_NAME                     ' || '| CURRENT_SIZE_MB |' || ' CURRENT_PCT% ' || '|');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------------');
  open c_subcom;
    loop fetch c_subcom into v_subcom;
    exit when c_subcom%notfound;
    dbms_output.put_line('| ' || lpad(v_subcom.RANK,4)|| ' | ' || rpad(v_subcom.SUBPOOL,22) ||' | '|| rpad(v_subcom.NAME,34) || ' | '|| lpad(v_subcom.MB || ' M',15) || ' | '|| lpad(v_subcom.pct || '%',12) || ' |');
    end loop;
    dbms_output.put_line('-------------------------------------------------------------------------------------------------------');
  close c_subcom;
**/
end;
/

var pbsts varcahr2(1000)
exec :pbsts := dbms_spm.evolve_sql_plan_baseline
('&sql_handle',
 '&plan_name',
 VERIFY=>'NO',
 COMMIT=>'YES');
-- evolue the baseline with verify on
-- @sql_baseline_enable2.sql <sql_handle>
--

SELECT dbms_spm.evolve_sql_plan_baseline(
         sql_handle => '&sql_handle',
         plan_name  => '',
         time_limit => 10,
         verify     => 'yes',
         commit     => 'yes'
       )
FROM dual;
-- sql_baseline.sql <sql_id_to_load> <plan_hash_value> <sql_handle> <old_plan_name_to_drop>
-- Sidney Chen(Nov 3)

SET SERVEROUTPUT ON

DECLARE
  ret PLS_INTEGER;
BEGIN
  ret := dbms_spm.load_plans_from_cursor_cache(
           sql_id          => '&sql_id',
           plan_hash_value => '&plan_hash_value',
           sql_handle      => '&sql_handle'
         );
  dbms_output.put_line(ret || ' SQL plan baseline(s) created');
  ret := dbms_spm.drop_sql_plan_baseline(
           sql_handle => '&1',
           plan_name  => '&4'
         );
  dbms_output.put_line(ret || ' SQL plan baseline(s) dropped');
END;
/
