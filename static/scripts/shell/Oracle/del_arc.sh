#!/bin/bash
export SQLPATH=''
LOGFILE=/home/oracle/yc/delarch`date +%y%m%d%H`.log
echo > ${LOGFILE}
for i in `ps -ef|grep ora_smon|grep -v grep|awk '{print $8}'`
do
ORASID=${i##*'_'}
export ORACLE_SID=$ORASID
ORAHOME=$(cat /etc/oratab|grep "^${ORASID}:"|awk -F ':' '{print $2}')

if [ xq$ORAHOME == xq ]
then
ORAHOME=$(cat /home/oracle/yc/oratabs|grep "^${ORASID}:"|awk -F ':' '{print $2}')
fi

if [ xq$ORAHOME == xq ]
then
echo "            "  >> ${LOGFILE}
echo "实例名${ ORASID}未找到匹配的ORACLE_HOME"  >> ${LOGFILE}
echo "            "  >> ${LOGFILE}
continue
fi

export ORACLE_HOME=$ORAHOME
export PATH=$ORACLE_HOME/bin:$PATH

sqlplus / as sysdba <<EOF
col val new_value v_tag
select (case when instance_number=(select min(instance_number) from gv\$instance where status='OPEN') then 1 else 0 end) val from v\$instance ;
exit v_tag
EOF

val=$?

if [ $val = 1 ]
then
rman target / log ${LOGFILE} append<<EOF
crosscheck archivelog all;
delete  noprompt expired archivelog all;
delete  noprompt archivelog until time 'sysdate-1';
exit;
EOF
fi

done

cd /home/oracle/yc
find . -ctime +7 -name "delarch*.log" | xargs rm -f


