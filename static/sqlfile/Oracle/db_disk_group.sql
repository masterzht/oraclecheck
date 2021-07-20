SELECT
       'db_check_db_disk_group' as "db_check_db_disk_group",
       NAME,
       STATE,
       TYPE,
       OFFLINE_DISKS,
       round(TOTAL_MB/1024) TOTAL_GB,
       round(FREE_MB/1024) FREE_GB,
       round(((TOTAL_MB-FREE_MB)/TOTAL_MB)*100,2)||'%' USED_PCT
FROM V$ASM_DISKGROUP;
