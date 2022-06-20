#!/bin/bash
export SQLPATH=''
alias rm='rm'
dict='v$parameter'

for i in `ps -ef|grep ora_smon|grep -v grep|awk '{print $8}'`
do
ORASID=${i##*'_'}
export ORACLE_SID=$ORASID
ORAHOME=$(cat /etc/oratab|grep "^${ORASID}:"|awk -F ':' '{print $2}')

if [ xq$ORAHOME == xq ]
then
ORAHOME=$(cat /home/oracle/luoji/oratabs|grep "^${ORASID}:"|awk -F ':' '{print $2}')
fi

if [ xq$ORAHOME == xq ]
then
continue
fi

export ORACLE_HOME=$ORAHOME
export PATH=$ORACLE_HOME/bin:$PATH

val=`sqlplus -S / as sysdba   <<EOF
set heading off linesize 200 
col value for a100
select value from $dict where name='audit_file_dest';
exit
EOF`

cd $val
find . -type f -name "*.aud"|xargs -n 1000 rm
done


