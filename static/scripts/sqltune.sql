SET SERVEROUTPUT ON

-- Tuning task created for specific a statement from the AWR.
DECLARE
  l_sql_tune_task_id  VARCHAR2(100);
BEGIN
  l_sql_tune_task_id := DBMS_SQLTUNE.create_tuning_task (
                          begin_snap  => 28809,
                          end_snap    => 28810,
                          sql_id      => '1zp1p359ppm80',
                          scope       => DBMS_SQLTUNE.scope_comprehensive,
                          task_name   => '1zp1p359ppm80_tuning_task',
                          description => 'Tuning task for statement 1zp1p359ppm80 in AWR.');
  DBMS_OUTPUT.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
END;
/

-- Tuning task created for specific a statement from the cursor cache.
DECLARE
  l_sql_tune_task_id  VARCHAR2(100);
BEGIN
  l_sql_tune_task_id := DBMS_SQLTUNE.create_tuning_task (
                          sql_id      => '1zp1p359ppm80',
                          scope       => DBMS_SQLTUNE.scope_comprehensive,
                          task_name   => '1zp1p359ppm80_tuning_task',
                          description => 'Tuning task for statement 1zp1p359ppm80.');
  DBMS_OUTPUT.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
END;
/

-- Tuning task created from an SQL tuning set.
DECLARE
  l_sql_tune_task_id  VARCHAR2(100);
BEGIN
  l_sql_tune_task_id := DBMS_SQLTUNE.create_tuning_task (
                          sqlset_name => 'test_sql_tuning_set',
                          scope       => DBMS_SQLTUNE.scope_comprehensive,
                          time_limit  => 60,
                          task_name   => 'sqlset_tuning_task',
                          description => 'Tuning task for an SQL tuning set.');
  DBMS_OUTPUT.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
END;
/

-- Tuning task created for a manually specified statement.
DECLARE
  l_sql               VARCHAR2(500);
  l_sql_tune_task_id  VARCHAR2(100);
BEGIN
  l_sql := 'SELECT e.*, d.* ' ||
           'FROM   emp e JOIN dept d ON e.deptno = d.deptno ' ||
           'WHERE  NVL(empno, ''0'') = :empno';

  l_sql_tune_task_id := DBMS_SQLTUNE.create_tuning_task (
                          sql_text    => l_sql,
                          bind_list   => sql_binds(anydata.ConvertNumber(100)),
                          user_name   => 'scott',
                          scope       => DBMS_SQLTUNE.scope_comprehensive,
                          time_limit  => 60,
                          task_name   => 'emp_dept_tuning_task',
                          description => 'Tuning task for an EMP to DEPT join query.');
  DBMS_OUTPUT.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
END;
/


--running the tuning task
EXEC DBMS_SQLTUNE.execute_tuning_task(task_name => '1zp1p359ppm80_tuning_task');

SELECT task_name, status FROM dba_advisor_log WHERE task_name like '1zp1p359ppm80_tuning_task';

SET LONG 10000;
SET PAGESIZE 1000
SET LINESIZE 200
SELECT DBMS_SQLTUNE.report_tuning_task('1zp1p359ppm80_tuning_task') AS recommendations FROM dual;
SET PAGESIZE 24


--accept sql profile
DECLARE
my_sqlprofile_name VARCHAR2(30);
BEGIN  
my_sqlprofile_name := DBMS_SQLTUNE.ACCEPT_SQL_PROFILE (task_name => '1zp1p359ppm80_tuning_task',name => '1zp1p359ppm80_sql_profile');
END;
/

EXEC DBMS_SQLTUNE.DROP_SQL_PROFILE('coe_atkdk3q54jhy4_522459436');

--drop sql profile

--drop tuning task
EXEC DBMS_SQLTUNE.drop_tuning_task (task_name => 'coe_4b061vggv5xc9_514643384');

--set table
exec dbms_stats.set_table_stats('CS2_PARTY_OWNER', 'CS2_CT_MVMT', num_rows=>null, no_invalidate=>false);
--set columns
exec DBMS_STATS.SET_COLUMN_STATS('CS2_SHIPMENT_FOLDER_OWNER','SHIPMENT_FOLDER_REFERENCE','REFERENCE_NUMBER',distcnt=>8338272,density=>1/8338272,no_invalidate=>false,force=>true);
exec DBMS_STATS.SET_COLUMN_STATS('CS2_SHIPMENT_FOLDER_OWNER','SHIPMENT_FOLDER_REFERENCE','SYS_NC00006$',distcnt=>8338272,density=>1/8338272,no_invalidate=>false,force=>true);
exec DBMS_STATS.SET_COLUMN_STATS('MCCIOWNER','MCCI_ILM_INTERACTION_REF','REF_KEY_VALUE',distcnt=>10439783,density=>1/10439783,no_invalidate=>false,force=>true)

--lock table
exec DBMS_STATS.LOCK_TABLE_STATS('CS2_SHIPMENT_FOLDER_OWNER','SHIPMENT_FOLDER_REFERENCE');


