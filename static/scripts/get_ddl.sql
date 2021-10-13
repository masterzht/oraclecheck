set serveroutput on size 1000000
set timing off
set serveroutput on
set feedback off
set verify off
set linesize 500
undefine object_name

var object_name varchar2(100);
var owner varchar2(100);
alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
begin
  :object_name := upper('&object_name');
end;
/
declare

   cursor c_obj is select owner,object_type from dba_objects where object_name = :object_name;
   v_obj c_obj%rowtype;
   cursor c_ddl is select dbms_metadata.get_ddl(case when object_type like 'PACKAGE%' then 'PACKAGE' 
                                                     when object_type like 'DATABASE LINK' then 'DB_LINK' 
                                                     when object_type like 'MATERIALIZED VIEW' then 'MATERIALIZED_VIEW' 
                                                     when object_type = 'INDEX' then 'INDEX' 
                                                     else object_type end, 
                                                object_name, owner) as object_ddl 
                    from dba_objects 
                    where object_name = :object_name 
                    AND object_type not like '%PARTITION';

   v_ddl c_ddl%rowtype;

   cursor c_cons is select case when co.constraint_type <> 'R' 
            then dbms_metadata.get_ddl('CONSTRAINT',co.constraint_name,co.owner) 
            when co.constraint_type = 'R' 
            then dbms_metadata.get_ddl('REF_CONSTRAINT',co.constraint_name,co.owner) end as text
    from dba_constraints co, dba_cons_columns cc
    where co.owner              = cc.owner
    and co.table_name         = cc.table_name
    and co.constraint_name    = cc.constraint_name
    and co.table_name = :object_name
    order by
     co.owner,
     co.table_name,
     co.constraint_type,
     co.constraint_name;
     v_cons c_cons%rowtype;

begin
  dbms_metadata.set_transform_param( dbms_metadata.session_transform,'SQLTERMINATOR', TRUE);
  dbms_output.put_line('
Display The Object Type in The Database');
  dbms_output.put_line('======================');
  dbms_output.put_line('------------------------------------------------------');
  dbms_output.put_line('| OWNER            |' || ' OBJECT_TYPE                     '   || '|');
  dbms_output.put_line('------------------------------------------------------');
  open c_obj;
    loop fetch c_obj into v_obj;
    exit when c_obj%notfound;
    dbms_output.put_line('| ' || rpad(v_obj.OWNER,16) ||' | '|| rpad(v_obj.object_type,32) || '|');
    dbms_output.put_line('------------------------------------------------------');
    end loop;
  close c_obj;


  dbms_output.put_line('
Show The Object DDL Information)');
  dbms_output.put_line('======================');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| OBJECT DDL                                                                                                      |');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------------------------');
  open c_ddl;
    loop fetch c_ddl into v_ddl;
    exit when c_ddl%notfound;
    dbms_output.put_line(v_ddl.object_ddl);
    dbms_output.put_line('-------------------------------------------------------------------------------------------------------------------');
    end loop;
  close c_ddl;
  if v_obj.object_type like 'TABLE%' then 

  dbms_output.put_line('
Constraint DDL Information if The Object is A Table');
  dbms_output.put_line('======================');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| Constraint DDL                                                                                                  |');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------------------------');
  open c_cons;
    loop fetch c_cons into v_cons;
    exit when c_cons%notfound;
    dbms_output.put_line(v_cons.text);
    dbms_output.put_line('-------------------------------------------------------------------------------------------------------------------');
    end loop;
  close c_cons;
   end if;
end;
/
