
vi restore_arch.sh
#!/bin/bash
source /home/oracle/.bash_profile
rman target / << eof
run{
allocate channel c1 device type disk;
allocate channel c2 device type disk;
allocate channel c3 device type disk;
allocate channel c4 device type disk;
allocate channel c5 device type disk;
allocate channel c6 device type disk;
allocate channel c7 device type disk;
allocate channel c8 device type disk;
allocate channel c9 device type disk;
allocate channel c10 device type disk;
allocate channel c11 device type disk;
backup current controlfile format '/u01/app/ctl_bk_%s_%p_%t';
BACKUP 
    as compressed backupset tag forstandby_1101
    filesperset 20
    database format '/u01/app/full_bk_%s_%p_%t';
sql 'alter system archive log current';
BACKUP as compressed backupset tag forstandby_1101 archivelog all format '/u01/app/arch_bk_%s_%p_%t';
release channel c1;
release channel c2;
release channel c3;
release channel c4;
release channel c5;
release channel c6;
release channel c7;
release channel c8;
release channel c9;
release channel c10;
release channel c11;
}
exit;
eof
--set lines 180
--set pages 1000
COL STATUS FORMAT A9
COL HRS FORMAT 999.99
COL C_RATIO FORMAT 99.99
COL in_size for A10
COL out_size for A10

SELECT SESSION_KEY, INPUT_TYPE, STATUS,
           TO_CHAR(START_TIME,'mm/dd/yy hh24:mi') start_time,
           TO_CHAR(END_TIME,'mm/dd/yy hh24:mi')   end_time,
           ELAPSED_SECONDS/3600                   hrs,
           COMPRESSION_RATIO c_ratio,
           INPUT_BYTES_DISPLAY in_size,
           OUTPUT_BYTES_DISPLAY out_size
FROM V$RMAN_BACKUP_JOB_DETAILS
where input_type='DB FULL'
ORDER BY SESSION_KEY;
