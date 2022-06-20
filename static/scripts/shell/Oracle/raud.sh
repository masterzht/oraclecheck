#!/bin/bash
. /home/oracle/.bash_profile

alias rm='rm'
dict=v\$parameter
for i in `ps -ef|grep ora_smon|grep -v grep|awk '{print $8}'`
do
ORACLE_SID=${i##*'_'}
export ORACLE_SID=$ORACLE_SID
val=`sqlplus -S / as sysdba   <<EOF
set heading off linesize 200 
col value for a100
select value from $dict where name='audit_file_dest';
exit
EOF`

cd $val
ls | xargs -n 1000 rm -f
done
