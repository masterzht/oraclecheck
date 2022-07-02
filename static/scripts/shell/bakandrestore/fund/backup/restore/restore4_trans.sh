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
#加载通用函数
SHELLPATH=${shellpath}

source $SHELLPATH/func

if [ "$DBTYPE" == "oracle" ] && [ "$SUBDBTYPE" == "dm" ];then
		restore $FILENAME$BACKUPFLAG$BUSINTYPE.dmp
elif [ "$DBTYPE" == "mysql" ] && [ "$SUBDBTYPE" == "lightdb" ];then
		restoretable $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE
elif [ "$DBTYPE" == "mysql" ] && [ "$SUBDBTYPE" == "pg" ];then
		restore $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE
elif [ "$DBTYPE" == "oracle" ] && [ "$SUBDBTYPE" == "oceanbase" ];then
		restore $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE
elif [ "$DBTYPE" == "mysql" ];then
    restore $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE.sql
elif [ "$DBTYPE" == "oracle" ];then
    restore $FILENAME$BACKUPFLAG$BUSINTYPE%U.dmp
else
    echo "数据库类型不匹配"
    exit -1
fi

#使用示例   

#ETF公共库恢复数据示例,由于公共库共用，备份时只会备份一部分数据，此类数据需要先删后插
#deldatabybusintype tbsysarg tbbankta tbsellerfiletype
#restore /home/bta60/backup/etf/$BACKUPID/pubdata.sql
#根据实际备份情况自行扩展
#restore /home/bta60/backup/etf/$BACKUPID/xxxxxxxxx.sql
#restore ${BACKUPDIR}/${FILENAME}
#restore ${BACKUPDIR}/${FILENAME}



#ETF账户库恢复数据示例,由于账户库共用，备份时只会备份一部分数据，此类数据需要先删后插
#deldatabybusintype tbclient tbclientseller 
#restore /home/bta60/backup/etf/$BACKUPID/accdata.sql
#根据实际备份情况自行扩展
#restore /home/bta60/backup/etf/$BACKUPID/xxxxxxxxx.sql

#ETF交易库恢复数据示例，交易库ETF专用,全库备份恢复即可
#restore /home/bta60/backup/etf/$BACKUPID/transdata.sql

