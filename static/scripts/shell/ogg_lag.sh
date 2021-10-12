### create the table in ogg database  
#create table sys.ogg_lag
#(current_time date,program VARCHAR2(100),STATUS VARCHAR2(100), groups VARCHAR(100), log_at_chkpt VARCHAR2(100),time_since_chkpt varchar2(100));
#create index oggdb.i_ogg_lag_d on oggdb.ogg_lag(current_time desc);

### add the crontab -e 
#*/10 * * * * sh /home/oracle/scripts/shell/ogg_lag.sh > /home/oracle/scripts/shell/ogg_lag.sql 2>&1


############################
source /home/oracle/.bash_profile

# define variables
SQLFILE='/home/oracle/scripts/shell/ogg_lag.sql'  
FLAG="','"
FLAG1="'"
TABLE_NAME="sys.ogg_lag" #insert table

/odc/ggsci << EOF 
info all 
EOF

sed -i '/GGSCI/d' $SQLFILE        #delete unnessary
sed -i '/GoldenGate/d' $SQLFILE   #delete unnessary
sed -i '/Copyright/d' $SQLFILE    #delete unnessary
sed -i '/Version/d' $SQLFILE      #delete unnessary
sed -i '/optimized/d' $SQLFILE    #delete unnessary
sed -i '/Program/d' $SQLFILE      #delete unnessary
sed -i '/MANAGER/d' $SQLFILE      #delete unnessary
sed -i '/^$/d' $SQLFILE           #delete null line
sed -i 's/[ ][ ]*/ /g' $SQLFILE   #multi ' ' to 1 ' ' 

sed -i 's/.$//g' $SQLFILE         #delete last ' '
sed -i 's/[ ]/'"$FLAG"'/g' $SQLFILE  #' ' to ','
sed -i 's/^/insert into '"$TABLE_NAME"' values (sysdate,'"$FLAG1"'&/g' $SQLFILE #add sql head
sed -i 's/$/&'"$FLAG1"');/g' $SQLFILE #add sql end
echo 'COMMIT;' >> $SQLFILE

for i in `ps -ef|grep ora_smon|grep -v grep|awk '{print $8}'`
do
ORACLE_SID=${i##*'_'}
export ORACLE_SID=$ORACLE_SID
val=`sqlplus -S / as sysdba   <<EOF
@$SQLFILE
exit
EOF`
done

create or replace procedure P_chkstream is
 -- v_passtm varchar2(200);
  v_dsgtm  number;
  V_H1 number;
  V_M1 number;
  V_S1 number;
  V_H2 number;
  V_M2 number;
  V_S2 number;
  v_errstr varchar2(500);
  v_db     varchar2(10);
begin
  v_db := 'OGG';

  select TO_NUMBER(substr(max(LOG_AT_CHKPT),1,2)) , TO_NUMBER(substr(max(LOG_AT_CHKPT),4,2)),to_number(substr(max(LOG_AT_CHKPT),7,2)) INTO V_H1,V_M1,V_S1 from (select LOG_AT_CHKPT from ogg_lag order by current_time desc
  ) where rownum <6;
 select TO_NUMBER(substr(max(TIME_SINCE_CHKPT),1,2)) , TO_NUMBER(substr(max(TIME_SINCE_CHKPT),4,2)),to_number(substr(max(TIME_SINCE_CHKPT),7,2)) INTO V_H2,V_M2,V_S2 from (select TIME_SINCE_CHKPT from ogg_lag order by current_time desc
  ) where rownum <6;
  if ((v_m1+v_m2) > 5 and (v_h1+v_h2) = 0) or ((v_h1+v_h2) <> 0) then
    insert into itlog.send_pool
      (MOBILE, CONTENT, USERID)
    values
      ('13645744064', 'OGG同步传播时间有'||(v_h1+v_h2) ||'小时' || (v_m1+v_m2)|| '分钟' || (v_s1+v_s2)||'秒延时,请注意！', 'P_chkstream');
    insert into itlog.send_pool
      (MOBILE, CONTENT, USERID)
    values
      ('13515880377', 'OGG同步传播时间有'||(v_h1+v_h2) ||'小时' || (v_m1+v_m2)|| '分钟' || (v_s1+v_s2)||'秒延时,请注意！', 'P_chkstream');
  end if;
  commit;
end;
/

