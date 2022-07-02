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
BACKUPMODE=${backupmode}
FILENAME=${filename}
PARALLEL=${parallel}
COMPRESSION=${compression}
TABLES="TBFUND"
BACKUPTABLES="${backuptables}"
TENANT=${tenant}
CLUSTER=${cluster}
BACKUPDATE=${backupdate}
#找到上级目录的func文件
SHELLPATH=${shellpath}

source $SHELLPATH/func

if [ "$BACKUPMODE" == "1" ];then
 if [ "$DBTYPE" == "oracle" ] && [ "$SUBDBTYPE" == "dm" ];then
	if [ "$BACKUPTABLES" == "" ]; then
		expdb $FILENAME$BACKUPFLAG$BUSINTYPE.dmp tbsequence
	else
	    exptable $FILENAME$BACKUPFLAG$BUSINTYPE.dmp
	fi
 elif [ "$DBTYPE" == "mysql" ] && [ "$SUBDBTYPE" == "pg" ];then
	if [ "$BACKUPTABLES" == "" ]; then
		expdb $FILENAME$BACKUPFLAG$BUSINTYPE tbsequence
	else
	    exptable $FILENAME$BACKUPFLAG$BUSINTYPE
	fi
 elif [ "$DBTYPE" == "mysql" ] && [ "$SUBDBTYPE" == "lightdb" ];then
	if [ "$BACKUPTABLES" == "" ]; then
		expdb $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE
	else
	    exptable $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE
	fi
 elif [ "$DBTYPE" == "oracle" ] && [ "$SUBDBTYPE" == "oceanbase" ];then
		expdb $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE tbsequence
 elif [ "$DBTYPE" == "mysql" ];then
	if [ "$BACKUPTABLES" == "" ]; then
		expdb $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE.sql
	else
	    exptable $BACKUPDIR/$FILENAME$BACKUPFLAG$BUSINTYPE.sql
	fi
 elif [ "$DBTYPE" == "oracle" ];then
	if [ "$BACKUPTABLES" == "" ]; then
		expdb $FILENAME$BACKUPFLAG$BUSINTYPE%U.dmp 
	else
	    exptable $FILENAME$BACKUPFLAG$BUSINTYPE%U.dmp
	fi
 else
    echo "数据库类型不匹配"
    exit -1
 fi
elif [ "$BACKUPMODE" == "0" ];then
 if [ "$DBTYPE" == "oracle" ] && [ "$SUBDBTYPE" == "dm" ];then
	expdb $FILENAME$BACKUPFLAG$BUSINTYPE.dmp 
 elif [ "$DBTYPE" == "mysql" ] && [ "$SUBDBTYPE" == "pg" ];then
	expdb $FILENAME$BACKUPFLAG$BUSINTYPE 
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
fi
#exptables $FILENAME$BACKUPFLAG$BUSINTYPEetf%U.dmp TBETFCSDCSHACCDATA TBETFCSDCSZACCDATA

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
