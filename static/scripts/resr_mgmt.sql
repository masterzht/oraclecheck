--p1/p2/p3
select group_or_subplan, mgmt_p1, mgmt_p2, mgmt_p3, mgmt_p4, mgmt_p5, mgmt_p6, mgmt_p7, mgmt_p8, max_utilization_limit from dba_rsrc_plan_directives where plan = (select name from v$rsrc_plan where is_top_plan = 'TRUE');

select plan, group_or_subplan, type, cpu_p1, cpu_p2, cpu_p3, cpu_p4, status
from dba_rsrc_plan_directives
where plan='P_PLAN'
order by 1,2,3,4,5,6;

--

select consumer_group,cpu_method, status from dba_rsrc_consumer_groups order by 1;

select plan, cpu_method, status from dba_rsrc_plans order by 1;

select * from dba_rsrc_consumer_group_privs;

select to_char(m.begin_time, 'HH:MI') time, m.consumer_group_name, m.cpu_consumed_time / 60000 avg_running_sessions, m.cpu_wait_time / 60000 avg_waiting_sessions, d.mgmt_p1*(select value from v$parameter where name = 'cpu_count')/100 allocation from v$rsrcmgrmetric_history m, dba_rsrc_plan_directives d, v$rsrc_plan p where m.consumer_group_name = d.group_or_subplan and p.name = d.plan order by m.begin_time, m.consumer_group_name


--session px limit from rsrc 

select s.SID, s.SERIAL#, s.username ,rpd.plan,
       s.RESOURCE_CONSUMER_GROUP,
       rpd.PARALLEL_DEGREE_LIMIT_P1 
from   v$session s, 
       DBA_RSRC_CONSUMER_GROUPS rcg,
       DBA_RSRC_PLAN_DIRECTIVES rpd ,
       V$RSRC_CONSUMER_GROUP vcg
where  s.RESOURCE_CONSUMER_GROUP is not null
   and rcg.CONSUMER_GROUP = s.RESOURCE_CONSUMER_GROUP
   and rcg.status = 'ACTIVE'
   and rpd.GROUP_OR_SUBPLAN = rcg.CONSUMER_GROUP
   and rpd.status = 'ACTIVE'
   and vcg.name = s.RESOURCE_CONSUMER_GROUP;

--log

select group_or_subplan, mgmt_p1, mgmt_p2, mgmt_p3, mgmt_p4, mgmt_p5, mgmt_p6, mgmt_p7, mgmt_p8, max_utilization_limit from dba_rsrc_plan_directives where plan = (select name from v$rsrc_plan where is_top_plan = 'TRUE');

GROUP_OR_SUBPLAN       MGMT_P1  MGMT_P2  MGMT_P3  MGMT_P4  MGMT_P5  MGMT_P6  MGMT_P7  MGMT_P8 MAX_UTILIZATION_LIMIT
--------------------- -------- -------- -------- -------- -------- -------- -------- -------- ---------------------
APP                          0       50        0        0        0        0        0        0
ORA$AUTOTASK_SUB_PLAN        0        0        0        0        0        0        0        0
OTHER_GROUPS                 0        0        0        0        0        0        0        0
P1                          80        0        0        0        0        0        0        0
SYS_GROUP                    0        0        0        0        0        0        0        0
ORA$DIAGNOSTICS              0        0        0        0        0        0        0        0

6 rows selected.


select group_or_subplan, mgmt_p1, mgmt_p2, mgmt_p3, mgmt_p4, mgmt_p5, mgmt_p6, mgmt_p7, mgmt_p8, max_utilization_limit from dba_rsrc_plan_directives where plan = 'CATHY_PLAN';
