col jobs_what head WHAT for a50
col jobs_interval head INTERVAL for a40

col jobs_job_name head JOB_NAME for a40
col jobs_program_name head PROGRAM_NAME for a40

col log_user for A20
col owner for A20

select log_user, job, what jobs_what, last_date, next_date, interval jobs_interval, failures, broken,instance from dba_jobs;

select 
	owner		  jobs_owner
  , job_name      jobs_job_name
  , program_name  jobs_program_name
  , state         jobs_state
  , to_char(start_date, 'YYYY-MM-DD HH24:MI') start_date
  , to_char(next_run_date, 'YYYY-MM-DD HH24:MI') next_run_date
  , enabled 
from 
    dba_scheduler_jobs
/


select client_name,job_name,job_start_time from dba_autotask_job_history;

select job || ' '|| what, failures from dba_jobs where failures > 0
union all
select JOB_NAME, count(*)
FROM dba_scheduler_job_log
where
log_date > sysdate - 300/86400 and
STATUS != 'SUCCEDED'
group by job_name;

SELECT /*+ NO_MERGE */
       OWNER,OWNER
  FROM dba_scheduler_job_log
 WHERE log_date > SYSDATE - 7
 ORDER BY
       log_id DESC,
       log_date DESC;
col jobs_what head WHAT for a50
col jobs_interval head INTERVAL for a40

col jobs_job_name head JOB_NAME for a40
col jobs_program_name head PROGRAM_NAME for a40

col log_user for A20
col owner for A20

select log_user, job, what jobs_what, last_date, next_date, interval jobs_interval, failures, broken,instance from dba_jobs;

select 
	owner		  jobs_owner
  , job_name      jobs_job_name
  , program_name  jobs_program_name
  , state         jobs_state
  , to_char(start_date, 'YYYY-MM-DD HH24:MI') start_date
  , to_char(next_run_date, 'YYYY-MM-DD HH24:MI') next_run_date
  , enabled 
from 
    dba_scheduler_jobs
/

col jobs_what head WHAT for a50
col jobs_interval head INTERVAL for a40

col jobs_job_name head JOB_NAME for a40
col jobs_program_name head PROGRAM_NAME for a40

select * from dba_jobs_running;

select
    job_name      jobs_job_name
  , program_name  jobs_program_name
  , state         jobs_state
  , to_char(start_date, 'YYYY-MM-DD HH24:MI') start_date
  , to_char(next_run_date, 'YYYY-MM-DD HH24:MI') next_run_date
  , enabled
from
    dba_scheduler_jobs
where
    state = 'RUNNING'
/

