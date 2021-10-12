set linesize 400
set serveroutput on
set feedback off
declare
    v_database_role varchar2(100) :=null;
    v_open_mode varchar2(100) :=null;
    v_protection_mode  varchar2(100) :=null;
    v_switchover  varchar2(100) :=null;
    v_force_logging varchar2(100) :=null;

  cursor c_lag is select inst_id,name,value from gv$dataguard_stats where name like '%lag%' order by inst_id,name;
  v_lag c_lag%rowtype;
  cursor c_max_sequence is select thread#,max(sequence#) as max_sequence from v$archived_log group by thread# order by thread#; 
  cursor c_dest_error is select inst_id,dest_name,
  decode(regexp_substr(destination,'((25[0-5]|2[0-4]\d|((1\d{2})|([1-9]?\d)))\.){3}(25[0-5]|2[0-4]\d|((1\d{2})|([1-9]?\d)))'),null,'None',
  regexp_substr(destination,'((25[0-5]|2[0-4]\d|((1\d{2})|([1-9]?\d)))\.){3}(25[0-5]|2[0-4]\d|((1\d{2})|([1-9]?\d)))')) as destination,
  decode(error,null,'None',error) as error from gv$archive_dest where destination is not null order by dest_id;
  v_dest_error c_dest_error%rowtype;
  v_max_sequence c_max_sequence%rowtype;
  cursor c_standby_lag is select inst_id,lpad(name,14) as name , value from gv$dataguard_stats where name like '%lag%' order by inst_id,name;
  v_standby_lag c_standby_lag%rowtype;
  cursor c_standby_max_seq is select thread#, max(sequence#) as mseq from v$archived_log where applied='YES' group by thread#; 
  v_standby_max_seq c_standby_max_seq%rowtype;
  cursor c_mrp is select thread#,process,status,sequence#,block#,blocks from v$managed_standby where PROCESS like 'MRP%' order by sequence#;
  v_mrp c_mrp%rowtype;
  cursor c_convert is select q'[alter system set ]' || name || q'[ = ']' || replace(value,', ',''',''') || q'[' scope=spfile;]' command from v$parameter where name in ('log_file_name_convert','db_file_name_convert');
  v_convert c_convert%rowtype;

begin
select database_role,open_mode,PROTECTION_MODE,SWITCHOVER_STATUS,FORCE_LOGGING into v_database_role,v_open_mode,v_protection_mode,v_switchover,v_force_logging from v$database;

  dbms_output.put_line('DG Information');
  dbms_output.put_line('=======================');
  dbms_output.put_line('DATABASE_ROLE       :   '|| v_database_role);
  dbms_output.put_line('OPEN_MODE           :   '|| v_open_mode);
  dbms_output.put_line('PROTECTION_MODE     :   '|| v_protection_mode);
  dbms_output.put_line('SWITCHOVER_STATUS   :   '|| v_switchover);
  dbms_output.put_line('FORCE_LOGGING       :   '|| v_force_logging);
if v_database_role = 'PRIMARY' then

  dbms_output.put_line('
Primary Current Max Sequence#');
  dbms_output.put_line('=======================');
  open c_max_sequence;
    loop fetch c_max_sequence into v_max_sequence;
    exit when c_max_sequence%notfound;
    dbms_output.put_line('-------------------------------------------------------------------------');
    dbms_output.put_line('thread# : '|| v_max_sequence.thread#  || '  |  ' || 'max sequence# :   '|| v_max_sequence.max_sequence);
    end loop;
  close c_max_sequence;

  dbms_output.put_line('
Primary Dest_id Error Information');
  dbms_output.put_line('=======================');
  dbms_output.put_line('--------------------------------------------------------------------------------------------');
  dbms_output.put_line('| inst# |' || ' DEST_NAME            ' || '| ERROR                               |' || ' DESTINATION ADDRESS ' || '|');
  dbms_output.put_line('--------------------------------------------------------------------------------------------');
  open c_dest_error;
    loop fetch c_dest_error into v_dest_error;
    exit when c_dest_error%notfound;
    dbms_output.put_line('| '|| lpad(v_dest_error.inst_id,5) || ' | ' || rpad(v_dest_error.dest_name,20) || ' | ' || rpad(v_dest_error.error,35) || ' | ' || lpad(v_dest_error.destination,19) || ' |');
    end loop;
    dbms_output.put_line('--------------------------------------------------------------------------------------------');
  close c_dest_error;
else 
  dbms_output.put_line('
Standby Current Apply Lag Information');
  dbms_output.put_line('=======================');
  open c_standby_lag;
    loop fetch c_standby_lag into v_standby_lag;
    exit when c_standby_lag%notfound;
    dbms_output.put_line('inst_id : ' || v_standby_lag.inst_id  || '  |  ' || 'name : ' || v_standby_lag.name || '  |  ' || 'value : ' || v_standby_lag.value);
    end loop;
  close c_standby_lag;

  dbms_output.put_line('
Standby Max Applied Archived Log Information');
  dbms_output.put_line('=======================');
  open c_max_sequence;
    loop fetch c_max_sequence into v_standby_max_seq;
    exit when c_max_sequence%notfound;
    dbms_output.put_line('thread# : ' || v_standby_max_seq.thread#  || '  |  ' || 'max sequence# : ' || v_standby_max_seq.mseq);
    end loop;
  close c_max_sequence;

  dbms_output.put_line('
MRP Processes Status Information');
  dbms_output.put_line('=======================');
  open c_mrp;
    loop fetch c_mrp into v_mrp;
    exit when c_mrp%notfound;
    dbms_output.put_line('thread# : ' ||v_mrp.thread#  || '  |  ' || 'PROCESS : ' ||v_mrp.PROCESS  || '  |  ' || 'STATUS :' ||v_mrp.STATUS || '  |  ' ||'SEQUENCE# :' || v_mrp.SEQUENCE# || '  |  ' ||'BLOCK# :' || v_mrp.BLOCK#);
    end loop;
  close c_mrp;
  dbms_output.put_line('
db_file_name_convert and log_file_name_convert in Physical Standby');
  dbms_output.put_line('=======================');
  open c_convert;
    loop fetch c_convert into v_convert;
    exit when c_convert%notfound;
    dbms_output.put_line(v_convert.command);
    end loop;
  close c_convert;  

end if;
end;
/






