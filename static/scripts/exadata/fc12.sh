###################################
### SCRIPT ########################
###################################

i=0
 
while true
do
i=`expr $i + 1`
j=`expr $i % 10`
if [ $j -eq 1 ]; then
   echo
   echo `date "+%Y-%m-%d %H:%M:%S"`
   echo "-------FC ALLOCATED (GB)------ ------FC WRITE (MB/sec)------ -----DISK WRITE (MB/sec)-----"
   echo "     ALLOC      USED     DIRTY 1ST WRITE OVERWRITE  POPULATE DISKWRITE      SKIP   SKIP_LG"
fi
 
dcli -g cell_group -l root cellcli -e "list metriccurrent FC_BY_ALLOCATED, FC_BY_USED, FC_BY_DIRTY, FC_IO_BY_W_FIRST_SEC, FC_IO_BY_W_OVERWRITE_SEC, FC_IO_BY_W_POPULATE_SEC, FC_IO_BY_DISK_WRITE_SEC, FC_IO_BY_W_SKIP_SEC, FC_IO_BY_W_SKIP_LG_SEC" | sed -e 's/://g' -e 's/,//g' | awk '
   BEGIN {FC_BY_ALLOCATED=0; FC_BY_USED=0; FC_BY_DIRTY=0; FC_IO_BY_W_FIRST_SEC=0; FC_IO_BY_W_OVERWRITE_SEC=0; FC_IO_BY_W_POPULATE_SEC=0; FC_IO_BY_DISK_WRITE_SEC=0; FC_IO_BY_W_SKIP_SEC=0; FC_IO_BY_W_SKIP_LG_SEC=0}
   /FC_BY_ALLOCATED/          {FC_BY_ALLOCATED          += $4; next}
   /FC_BY_USED/               {FC_BY_USED               += $4; next}
   /FC_BY_DIRTY/              {FC_BY_DIRTY              += $4; next}
   /FC_IO_BY_W_FIRST_SEC/     {FC_IO_BY_W_FIRST_SEC     += $4; next}
   /FC_IO_BY_W_OVERWRITE_SEC/ {FC_IO_BY_W_OVERWRITE_SEC += $4; next}
   /FC_IO_BY_W_POPULATE_SEC/  {FC_IO_BY_W_POPULATE_SEC  += $4; next}
   /FC_IO_BY_DISK_WRITE_SEC/  {FC_IO_BY_DISK_WRITE_SEC  += $4; next}
   /FC_IO_BY_W_SKIP_SEC/      {FC_IO_BY_W_SKIP_SEC      += $4; next}
   /FC_IO_BY_W_SKIP_LG_SEC/   {FC_IO_BY_W_SKIP_LG_SEC   += $4; next}
   END {/*printf("%10s%10s%10s%10s%10s%10s%10s%10s%10s\n", "ALLOC", "USED", "DIRTY", "1ST WRITE", "OVERWRITE", "POPULATE", "DISKWRITE", "SKIP", "SKIP_LG");*/
        printf("%10.1f%10.1f%10.1f%10d%10d%10d%10d%10d%10d\n", FC_BY_ALLOCATED/1000, FC_BY_USED/1000, FC_BY_DIRTY/1000, FC_IO_BY_W_FIRST_SEC, FC_IO_BY_W_OVERWRITE_SEC, FC_IO_BY_W_POPULATE_SEC, FC_IO_BY_DISK_WRITE_SEC*1024, FC_IO_BY_W_SKIP_SEC, FC_IO_BY_W_SKIP_LG_SEC)}

'

sleep 10

done
