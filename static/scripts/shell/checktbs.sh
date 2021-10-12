
source /home/oracle/.bash_profile
for i in `ps -ef|grep ora_smon|grep -v grep|awk '{print $8}'`
do
ORACLE_SID=${i##*'_'}
export ORACLE_SID=$ORACLE_SID

sqlplus / as sysdba <<EOF
declare
  sql_adddbfile varchar2(100);
  db_role       varchar2(30);
  inst_pos      number;
begin
  select database_role into db_role from v\$database;
  select (case when instance_number=(select min(instance_number) from gv\$instance where status='OPEN') then 1 else 0 end) into inst_pos from v\$instance;
 -- dbms_output.put_line(db_role);
  if db_role = 'PRIMARY' and inst_pos = 1 then
    for i_tbs in (select tablespace_name
                    from (select a.tablespace_name,
                                 c.allocation_type,
                                 c.segment_space_management,
                                 case mod(c.initial_extent, 1024 * 1024)
                                   when 0 then
                                    c.initial_extent / 1024 / 1024 || 'M'
                                   else
                                    c.initial_extent / 1024 || 'K'
                                 end initial_extent,
                                 a.total_Mbytes,
                                 a.current_Mb,
                                 a.current_Mb - b.free_Mbytes used_Mbytes,
                                 a.total_Mbytes - a.current_Mb +
                                 b.free_Mbytes free_Mbytes,
                                 trunc((a.total_Mbytes - a.current_Mb +
                                       b.free_Mbytes) / a.total_Mbytes * 100,
                                       2) pct_free,
                                 null dummy
                            from (select tablespace_name,
                                         sum(bytes) / 1024 / 1024 current_Mb,
                                         sum(case autoextensible
                                               when 'YES' then
                                                MAXBYTES / 1024 / 1024
                                               else
                                                bytes / 1024 / 1024
                                             end) total_MBytes
                                    from dba_data_files
                                   where tablespace_name not like 'UNDOTBS%'
                                   group by tablespace_name) a,
                                 (select tablespace_name,
                                         sum(bytes) / 1024 / 1024 free_Mbytes
                                    from dba_free_space
                                   where tablespace_name not like 'UNDOTBS%'
                                   group by tablespace_name) b,
                                 dba_tablespaces c
                           where a.tablespace_name = b.tablespace_name(+)
                             and a.tablespace_name = c.tablespace_name(+)) a
                   where free_Mbytes <= 10240) loop
      sql_adddbfile := 'alter tablespace ' || i_tbs.tablespace_name ||
                       ' add datafile '+DATA' size 1G autoextend on';

      execute immediate sql_adddbfile;
    end loop;
  else
    null;
  end if;
exception
  when others then
    raise;
   -- RAISE_APPLICATION_ERROR(-20001, 'add datafile error');
end;
/

exit;
EOF
done
