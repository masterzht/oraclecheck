COLUMN   policy ON FORMAT   a6
COLUMN   operation_type ON HEADING  'type' FORMAT   a10
col time_s format 99999

set lines 200

select sid, 
       operation_type,
       policy,
       round(ACTIVE_TIME/1000000) time_s,
       round(WORK_AREA_SIZE/1024/1024,3) workarea_MB,
       round(EXPECTED_SIZE/1024/1024,3) expected_MB,
       round(ACTUAL_MEM_USED/1024/1024,3) actual_MB,
       round(MAX_MEM_USED/1024/1024,3) maxused_MB,
       NUMBER_passes passes,
       TEMPSEG_SIZE
from v$sql_workarea_active
-- where operation_type like
/
