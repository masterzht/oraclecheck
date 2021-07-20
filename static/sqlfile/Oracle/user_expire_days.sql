 select
 'db_check_user_expire_days' as "db_check_user_expire_days",
 a.username,
 a.account_status,
 CASE B.LIMIT WHEN 'UNLIMITED' THEN NULL
 ELSE trunc(A.EXPIRY_DATE - SYSDATE)+b.limit
 END AS EXPIRED_DAYS,
 a.DEFAULT_TABLESPACE,
 a.TEMPORARY_TABLESPACE,
 case when c.granted_role = 'DBA' then 'Yes' else 'No' end as "HAS_DBA_ROLE"
from dba_users a,dba_profiles b,dba_role_privs c
where a.profile=b.profile and c.GRANTEE = a.username
and a.username <> 'SYS'
and b.RESOURCE_NAME='PASSWORD_GRACE_TIME'
and a.expiry_date is not null and b.limit <>'UNLIMITED'
order by a.created;
