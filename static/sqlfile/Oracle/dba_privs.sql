-- 5.4
select
       'db_check_' as "db_check_",
       a.grantee,
       granted_role,
       lpad(a.admin_option,6) as admin_option,
       lpad(a.default_role,6) as default_role,b.account_status
from dba_role_privs a,dba_users b
where a.grantee=b.username and
granted_role in( 'DBA','IMP_FULL_DATABASE')
and grantee not in('SYS','SYSTEM','DBA')
and b.account_status='OPEN'
order by 1;