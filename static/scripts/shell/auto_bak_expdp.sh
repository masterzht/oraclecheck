#!/bin/bash
. /home/oracle/.bash_profile
a=$(date +%Y%m%d_%H%M)
echo $a
/opt/oracle/products/12.2.0/bin/expdp  \'/as sysdba\' DIRECTORY=EXPDP_DATA dumpfile=$a.dp logfile=$a.lg full=yes COMPRESSION=all

cd /opt/oracle/oradata/expdp_data
find . -ctime +10 -name "*.lg"|xargs rm -f
find . -ctime +10 -name "*.dp"|xargs rm -f

lftp 122.224.104.250<<!
user devbak devbak
cd /data/bigdatabak
mput /opt/oracle/oradata/expdp_data/$a.dp /opt/oracle/oradata/expdp_data/$a.lg
close
bye
!
