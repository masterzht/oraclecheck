#!/bin/bash
. ~/.bashrc
date +"%Y%m%d_%H%M%S"             >> /home/lightdb/yc/del_arch.log &&
ltsql -U lightdb -p5555 -c "checkpoint;" >> /home/lightdb/yc/del_arch.log &&
echo "checkpoint complete"        >> /home/lightdb/yc/del_arch.log &&
lt_archivecleanup $PGHOME/pg_wal `lt_controldata  | grep "Latest checkpoint's REDO WAL file" | awk '{print $6}'` >> /home/lightdb/yc/del_arch.log &&
echo "archivelog delete complete" >> /home/lightdb/yc/del_arch.log