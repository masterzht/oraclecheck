set timing off
set serveroutput on
set feedback off
set verify off
set linesize 500
undefine username
var username varchar2(100);
alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
begin
  :username :=upper('&username');
end;
/
declare

    cursor c_user is select distinct
        a.username,
        a.default_tablespace,
        a.temporary_tablespace as temp_tbs,
        a.user_id,
        to_char(a.created,'yyyymmdd') as created,
        a.profile,
        a.account_status,
        b.lcount,
        sum(round(s.bytes/1024/1024/1024)) over(partition by s.owner) as USER_SEGMENT_GB,
        case when p.GRANTED_ROLE = 'DBA' then 'Yes' else 'No' end as DBA_PRIVS
from
        dba_users a, user$ b, dba_segments s ,dba_role_privs p,dba_profiles pr
where a.user_id = b.USER#
and a.username = s.owner
and p.grantee = a.username
and a.username not in
('SYSTEM','OWBSYS','XS$NULL','FLOWS_FILES','WMSYS','DIP','XDB','SYS','ANONYMOUS','QMONITOR','ORDPLUGINS',
'OUTLN','ORDSYS','SI_INFORMTN_SCHEMA','ORDDATA','OJVMSYS','SPATIAL_WFS_ADMIN_USR','MDSYS','LBACSYS','SPATIAL_CSW_ADMIN_USR',
'DVSYS','DBSNMP','APEX_PUBLIC_USER','APPQOSSYS','APEX_040200','ORACLE_OCM','AUDSYS','CTXSYS','MDDATA',
'APEX_030200','EXFSYS','MGMT_VIEW','OLAPSYS','SYSMAN','OWBSYS_AUDIT','WH_SYNC','GSMADMIN_INTERNAL')
order by created;
   v_user c_user%rowtype;
   cursor c_a is select a.username,
CASE B.LIMIT WHEN 'UNLIMITED' THEN NULL
     ELSE trunc(A.EXPIRY_DATE - SYSDATE)+b.limit END AS EXPIRED_DAYS
from dba_users a,dba_profiles b
where a.profile=b.profile
and a.account_status='OPEN'
and b.RESOURCE_NAME='PASSWORD_GRACE_TIME'
and a.expiry_date is not null
and b.limit <>'UNLIMITED';
    v_a c_a%rowtype;
begin
   
  dbms_output.put_line('
User Information');
  dbms_output.put_line('======================');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| USERNAME           |' || ' DEFAULT_TABLESPACE |' || ' DEFAULT_TEMP_TBS ' || '| USER_ID |' || ' CREATED  ' || '| PROFILE   |' || ' ACCOUNT_STATUS ' || '| LCOUNT ' || '| USER_GB ' || '| DBA PRIV '|| '|');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------');
  open c_user;
    loop fetch c_user into v_user;
    exit when c_user%notfound;
    dbms_output.put_line('| ' || rpad(v_user.USERNAME,18) || ' | ' || rpad(v_user.DEFAULT_TABLESPACE,18) ||' | '|| rpad(v_user.TEMP_TBS,16) || ' | ' || lpad(v_user.USER_ID,7) || ' | ' || lpad(v_user.CREATED,8) || ' | ' || rpad(v_user.PROFILE,9) || ' | ' || rpad(v_user.ACCOUNT_STATUS,14) || ' | ' || lpad(v_user.LCOUNT,6) || ' | ' || lpad(v_user.USER_SEGMENT_GB,7) || ' | ' || rpad(v_user.DBA_PRIVS,8) ||' |');
    end loop;
    dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------');
  close c_user;


end;
/




prompt ***************
prompt Current User DBA_ROLE_PRIVS
prompt ***************
select 'grant '||granted_role||' to '||grantee||decode(admin_option, 'YES', ' WITH ADMIN OPTION;',';') cmd 
from dba_role_privs where upper(grantee) = :username;
prompt ***************
prompt Current User dba_sys_privs
prompt ***************
select 'grant '||privilege||' to '||grantee||decode(admin_option, 'YES', ' WITH ADMIN OPTION;',';') cmd 
from dba_sys_privs where upper(grantee) = :username;
prompt ***************
prompt Current User dba_tab_privs
prompt ***************
select 'grant '||privilege||' on '||owner||'.'||table_name||' to '||grantee||decode(grantable, 'YES', ' WITH GRANT OPTION;',';') cmd 
from dba_tab_privs where upper(grantee) = :username;

set head on feedback on

