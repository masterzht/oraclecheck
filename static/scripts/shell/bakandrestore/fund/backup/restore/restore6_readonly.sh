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
BACKUPTABLES="${backuptables}"
TENANT=${tenant}
CLUSTER=${cluster}
BACKUPDATE=${backupdate}
#加载通用函数
SHELLPATH=${shellpath}
source $SHELLPATH/func

if [ "$DBTYPE" == "oracle" ] && [ "$SUBDBTYPE" == "dm" ];then
	if [ "$BACKUPTABLES" == "" ]; then
		restore $FILENAME$BACKUPFLAG$BUSINTYPE.dmp
	else
	   restoretable $FILENAME$BACKUPFLAG$BUSINTYPE.dmp
	fi
elif [ "$DBTYPE" == "mysql" ] && [ "$SUBDBTYPE" == "lightdb" ];then
		restore $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE
elif [ "$DBTYPE" == "mysql" ] && [ "$SUBDBTYPE" == "pg" ];then
		restore $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE
elif [ "$DBTYPE" == "oracle" ] && [ "$SUBDBTYPE" == "oceanbase" ];then
		restore $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE TBFUNDINCOMEHIS TBFUNDINTFECHANGE05FILEHIS TBFUNDINTFECHANGESYHIS TBFUNDPRFTFLOWDTLHIS TBFUNDPRFTFLOWHIS TBFUNDSHARECHGHIS TBFUNDSUBSCONFIRMHIS TBFUNDTACFMDETAILHIS TBFUNDTADIVDETAILHIS TBFUNDTATRANSCFMHIS TBFUNDTATRANSREQHIS TBFUNDUNSENDDIVHIS TBTAACCCFMHIS
elif [ "$DBTYPE" == "mysql" ];then
	if [ "$BACKUPTABLES" == "" ]; then
		restore $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE.sql
	else
	   restoretable $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE.sql
	fi
elif [ "$DBTYPE" == "oracle" ];then
	if [ "$BACKUPTABLES" == "" ]; then
		restore $FILENAME$BACKUPFLAG$BUSINTYPE%U.dmp
	else
	   restoretable $FILENAME$BACKUPFLAG$BUSINTYPE%U.dmp
	fi
else
    echo "数据库类型不匹配"
    exit -1
fi

#if [ "$DBTYPE" == "mysql" ];then
#    restore $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE.sql
#elif [ "$DBTYPE" == "oracle" ];then
#    restore $FILENAME$BACKUPFLAG$BUSINTYPE%U.dmp
#else
#    echo "数据库类型不匹配"
#    exit -1
#fi

