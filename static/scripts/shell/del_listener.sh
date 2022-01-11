#!/bin/sh
#Auto remove and backup listener.log
#Author cy
#Date 2022-1-11 14:38:58
typeset -l l_name
l_name=LISTENER
listener_full_name=`lsnrctl status $l_name |grep "Listener Log File"|awk '{ print $4 }'|sed -e 's/alert\/log.xml/trace\/'${l_name}'.log/g'`
zipname=HistoryListener.zip
filesize=`ls -l $listener_full_name |awk '{print $5}'`
maxsize=$((1230354730))
if [ $filesize -gt $maxsize ]
then
    echo "$filesize > $maxsize"
    set log_status off
    sleep 5s
    mv $filepath/$filename  $filepath/listener.old"`date +%Y-%m-%d_%H:%M:%S`"
    set log_status on
    zip $filepath/$zipname  $filepath/listener.old*
    sleep 240s
    rm   $filepath/listener.old*
else
    echo "$filesize < $maxsize , No need to move!"
fi