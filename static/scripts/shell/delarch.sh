#!/bin/bash
. /home/oracle/.bash_profile

for i in `ps -ef|grep ora_smon|grep -v grep|awk '{print $8}'`
do
ORACLE_SID=${i##*'_'}
export ORACLE_SID=$ORACLE_SID

sqlplus / as sysdba <<EOF
col val new_value v_tag
select (case when (select status from v\$instance) = 'OPEN' then 1 else 0 end) val from v\$instance ;
exit v_tag
EOF

val=$?

if [ $val = 1 ]
then
rman target / log /home/oracle/scripts/delarch`date +%y%m%d%H`.log append<<EOF
crosscheck archivelog all;
delete noprompt expired archivelog all;
delete noprompt archivelog until time 'sysdate-2';
exit;
EOF
fi

done

cd /home/oracle/scripts
find . -ctime +3 -name "delarch*.log" | xargs rm -f