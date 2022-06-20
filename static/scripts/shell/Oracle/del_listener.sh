#!/bin/sh
#Auto remove and backup listener.log
#Author cy
#Date 2022-1-11 14:38:58
typeset -l l_name
l_name=LISTENER
listener_full_name=`lsnrctl status $l_name |grep "Listener Log File"|awk '{ print $4 }'|sed -e 's/alert\/log.xml/trace\/'${l_name}'.log/g'`
echo "listener_full_name is :" $listener_full_name
zipname=HistoryListener.zip
filesize=`ls -l $listener_full_name |awk '{print $5}'`
maxsize=$((1230354730))
if [ $filesize -gt $maxsize ]
then
    echo "$filesize > $maxsize"
    listener set log_status off
    sleep 5s
    mv $listener_full_name  $listener_full_name"`date +%Y-%m-%d_%H:%M:%S`"
    sleep 5s
    listener set log_status on
    zip $listener_full_name  $filepath/listener.old*
    sleep 240s
    rm $filepath/listener.old*
else
    echo "$filesize < $maxsize , No need to move!"
fi


#语句写法：find 对应目录 -mtime +天数 -name "文件名" -exec rm -rf {} \;
#　例1：　将/usr/local/backups目录下所有10天前带"."的文件删除
#　　find /usr/local/backups -mtime +10 -name "*.*" -exec rm -rf {} \;
#　　find：linux的查找命令，用户查找指定条件的文件
#　　/usr/local/backups：想要进行清理的任意目录
#　　-mtime：标准语句写法
#　　＋10：查找10天前的文件，这里用数字代表天数，＋30表示查找30天前的文件
#　　"*.*"：希望查找的数据类型，"*.jpg"表示查找扩展名为jpg的所有文件，"*"表示查找所有文件，这个可以灵活运用，举一反三
#　　-exec：固定写法
#　　rm -rf：强制删除文件，包括目录
#　　{} \; ：固定写法，一对大括号+空格+\


#  find $1 -name "*.html" -mtime +1 -print0 |xargs -0 rm -v
