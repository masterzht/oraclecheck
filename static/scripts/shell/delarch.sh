alias rm='rm'
dict=v\$parameter
for i in `ps -ef|grep ora_smon|grep -v grep|awk '{print $8}'`
do
ORACLE_SID=${i##*'_'}
export ORACLE_SID=$ORACLE_SID

rman target / <<EOF
crosscheck archivelog all;
delete force noprompt archivelog until time 'sysdate-7';
exit;
EOF
done
######
#!/bin/bash
. /home/oracle/.bash_profile

for i in `ps -ef|grep ora_smon|grep -v grep|awk '{print $8}'`
do
ORACLE_SID=${i##*'_'}
export ORACLE_SID=$ORACLE_SID

sqlplus / as sysdba <<EOF
col val new_value v_tag
select (case when (select min(instance_number) from v\$instance) = 'OPEN' then 1 else 0 end) val from v\$instance ;
exit v_tag
EOF

val=$?

if [ $val = 1 ]
then
rman target / log /home/oracle/scripts/delarch`date +%y%m%d%H`.log append<<EOF
crosscheck archivelog all;
delete noprompt expired archivelog all;
delete noprompt archivelog until time 'sysdate-1';
exit;
EOF
fi

done

cd /home/oracle/luoji
find . -ctime +3 -name "delarch*.log" | xargs rm -f















### meichuang ###


. $HOME/.bash_profile
export ORACLE_SID=ora11g1
logtokeep=100
echo "*******delete applied archivelog*********\n"
### Get Max sequence# applied from Primary database ###
applied_seq1=`sqlplus -S "/as sysdba" << EOF
set heading off
set pagesize 0;
set feedback off;
set verify off;
set echo off;
select max(sequence#) from v\\$archived_log where applied = 'YES' and thread#=1;
exit;
EOF`
applied_seq2=`sqlplus -S "/as sysdba" << EOF
set heading off
set pagesize 0;
set feedback off;
set verify off;
set echo off;
select max(sequence#) from v\\$archived_log where applied = 'YES' and thread#=2;
exit;
EOF`

echo $applied_seq1
echo $applied_seq2

### Calculate the archive log to delete ###
arch_to_del1=$(($applied_seq1-$logtokeep))
arch_to_del2=$(($applied_seq2-$logtokeep))
###########################################
echo $arch_to_del1
echo $arch_to_del2
###########################################

if [ "$arch_to_del1" ]; then
rman target / <<EOF
crosscheck archivelog all;
delete noprompt archivelog until sequence $arch_to_del1 thread 1;
delete noprompt archivelog until sequence $arch_to_del2 thread 2;

exit;
EOF
fi