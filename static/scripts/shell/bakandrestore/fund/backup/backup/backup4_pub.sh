#!/bin/bash
##################################################通用数据恢复脚本################################################################################
#常量定义,程序中会替换为指定值之后执行 
DBTYPE=${dbtype}
SUBDBTYPE=${subdbtype}
BACKUPID=${backupid}
USER=${username}
PWD=${password}
HOST=${host}
PORT=${port}
DBNAME=${dbname}
CHARSET=${charset}
BACKUPDIR=${backupdir}
BUSINTYPE=${busintype}
BACKUPFLAG=${backupflag}
FILENAME=${filename}
PARALLEL=${parallel}
COMPRESSION=${compression}
TENANT=${tenant}
CLUSTER=${cluster}
BACKUPDATE=${backupdate}
SHELLPATH=${shellpath}
BACKUPMODE=${backupmode}

source $SHELLPATH/func

if [ "$BACKUPMODE" == "0" ];then
 if [ "$DBTYPE" == "oracle" ] && [ "$SUBDBTYPE" == "dm" ];then
		expdb $FILENAME$BACKUPFLAG$BUSINTYPE.dmp  
 elif [ "$DBTYPE" == "mysql" ] && [ "$SUBDBTYPE" == "pg" ];then
		expdb $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE  
 elif [ "$DBTYPE" == "mysql" ] && [ "$SUBDBTYPE" == "lightdb" ];then
	  expdb $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE
 elif [ "$DBTYPE" == "oracle" ] && [ "$SUBDBTYPE" == "oceanbase" ];then
		expdb $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE  
 elif [ "$DBTYPE" == "mysql" ];then
       expdb $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE.sql  
 elif [ "$DBTYPE" == "oracle" ];then
      expdb $FILENAME$BACKUPFLAG$BUSINTYPE%U.dmp  
 else
    echo "数据库类型不匹配"
    exit -1
 fi
elif [ "$BACKUPMODE" == "1" ];then
 if [ "$DBTYPE" == "oracle" ] && [ "$SUBDBTYPE" == "dm" ];then
		exptablelikes $FILENAME$BACKUPFLAG$BUSINTYPE.dmp TBBACKUPINFO TBRESTOREINFO
 elif [ "$DBTYPE" == "mysql" ] && [ "$SUBDBTYPE" == "pg" ];then
		expdb $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE TBBACKUPINFO TBRESTOREINFO
 elif [ "$DBTYPE" == "mysql" ] && [ "$SUBDBTYPE" == "lightdb" ];then
	 exptablelikes $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE TBBACKUPINFO TBRESTOREINFO
 elif [ "$DBTYPE" == "oracle" ] && [ "$SUBDBTYPE" == "oceanbase" ];then
		expdb $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE TBBACKUPINFO TBRESTOREINFO
 elif [ "$DBTYPE" == "mysql" ];then
    exptablelikes $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE.sql TBBACKUPINFO TBRESTOREINFO
 elif [ "$DBTYPE" == "oracle" ];then
    exptablelikes $FILENAME$BACKUPFLAG$BUSINTYPE%U.dmp TBBACKUPINFO TBRESTOREINFO
 else
    echo "数据库类型不匹配"
    exit -1
 fi
fi

#exptablewithbusintype $FILENAME$BACKUPFLAG$BUSINTYPE%U.dmp TBBANKTA TBSYSARG

#导出tbsysarg及tbbankta表的指定部分数据
#exptablewithbusintype $BACKUPDIR/pubdata222.sql tbsysarg tbbankta

#导出整库排除tbsysarg及tbbankta表
#expdb $BACKUPDIR/pubdata111.sql tbsysarg tbbankta

#公共库备份(基础表的备份)
#backupdb  $BACKUPDIR/pubdata_$BACKUPFLAG.sql

#公共库备份(ETF表的备份)
#backupdb  $BACKUPDIR/etfdata_$BACKUPFLAG.sql


#账户库备份(基础表的备份)
#backupdb  $BACKUPDIR/etfdata_$BACKUPFLAG.sql
#账户库备份(ETF表的备份)

#交易库 
#backupdb  $BACKUPDIR/etfdata_$BACKUPFLAG.sql
