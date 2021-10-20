#!/bin/bash
export ORACLE_HOME=/home/oracle
export ORACLE_SID=yao
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
backup current controlfile format '/home/oracle/bk/ctl_bk_%s_%p_%t';
BACKUP 
    as compressed backupset tag forstandby_1101
    filesperset 20
    database format '/home/oracle/bk/full_bk_%s_%p_%t';
sql 'alter system archive log current';
BACKUP as compressed backupset tag forstandby_1101 archivelog all format '/home/oracle/bk/arch_bk_%s_%p_%t';
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
}
exit;
eof